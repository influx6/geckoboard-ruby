module Geckoboard
  class DatasetsClient
    attr_reader :connection

    def initialize(connection)
      @connection = connection
    end

    def find_or_create(dataset_id, fields: nil, unique_by: nil)
      path = dataset_path(dataset_id)
      body = { fields: hashify_fields(fields) }
      body[:unique_by] = unique_by unless unique_by.nil?
      response = connection.put(path, body.to_json)

      data = JSON.parse(response.body)
      Dataset.new(self, data.fetch('id'), data.fetch('fields'))
    end

    def delete(dataset_id)
      path = dataset_path(dataset_id)
      connection.delete(path)
      true
    end

    def put_data(dataset_id, data)
      path = "#{dataset_path(dataset_id)}/data"
      connection.put(path, { data: data }.to_json)
      true
    end

    def post_data(dataset_id, data, options)
      path = "#{dataset_path(dataset_id)}/data"
      body = options.merge({ data: data }).to_json
      connection.post(path, body)
      true
    end

    private

    def dataset_path(dataset_id)
      "/datasets/#{CGI.escape(dataset_id)}"
    end

    def hashify_fields(fields)
      return fields if fields.is_a? Hash

      unless fields.respond_to?(:inject) && fields.all? { |field| field.is_a? Field }
        raise ArgumentError, "`fields:' must be either a hash of field definitions, or collection of `Geckoboard::Field' objects"
      end

      fields.inject({}) do |hash, field|
        hash.merge(field.id => field.to_hash)
      end
    end
  end
end
