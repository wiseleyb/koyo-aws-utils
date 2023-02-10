# frozen_string_literal: true

require "aws-sdk-core"
require "aws-sdk-s3"

module Koyo
  module AwsUtils
    # Simple common S3 operations
    # requires
    #   gem "aws-sdk", "~> 3"
    #   KOYO_S3_KEY=xyz
    #   KOYO_S3_SECRET=abc
    #   KOYO_S3_BUCKET=r48koyo
    #   KOYO_S3_REGION=us-eas-1
    class S3
      attr_accessor :bucket,
                    :headers,
                    :public_read,
                    :region,
                    :s3_client,
                    :s3_resource

      # TODO: move public_read to put_file?
      def initialize(bucket: ENV["KOYO_S3_BUCKET"],
                     public_read: ENV["KOYO_S3_PUBLIC"].to_s.downcase == "true",
                     region: ENV["KOYO_S3_REGION"])
        @bucket = bucket
        @public_read = public_read
        @region = region
        @headers = {}
        @headers[:acl] = "public-read" if public_read
        update_aws_config
        @s3_resource = Aws::S3::Resource.new
        @s3_client = Aws::S3::Client.new
      end

      def update_aws_config
        Aws.config.update(
          region: ENV["KOYO_S3_REGION"],
          credentials: Aws::Credentials.new(
            ENV["KOYO_S3_KEY"],
            ENV["KOYO_S3_SECRET"]
          )
        )
      end

      # returns list of objects
      # example: list_bucket.first.name
      def list_bucket
        s3_client.list_objects(bucket)
      end

      # basic bucket object
      def bucket_obj
        s3_resource.bucket(bucket)
      end

      # content_type: sets content_type for some file types - which sets how it
      #   downloads when clicked
      #   nil: does nothing
      #   csv: sets text/csv
      #   pdf: sets applcation/pdf
      def put_file(fname, key: nil, content_type: nil)
        key ||= key_from_file(fname)
        set_content_type(content_type, key)
        obj = s3_resource.bucket(bucket).object(key)
        obj.upload_file(fname, headers)
        key
        # if public_read
        #   obj.public_url
        # else
        #   signed_url(key)
        # end
      end

      # gets test of text file
      # # TODO: what to do with binary files?
      def get_file(key)
        resp = s3_client.get_object(bucket: bucket, key: key)
        resp.body.read
      end

      # deletes s3 key/file
      def delete_file(key)
        obj = s3_resource.bucket(bucket).object(key)
        obj.delete
      end

      # generates a S3 Key from a filename
      def key_from_file(fname)
        fname.to_s.split("/").last
      end

      # TODO: move to config
      def set_content_type(ftype, key)
        return if blank?(ftype)

        case ftype.to_sym
        when :csv
          headers[:content_disposition] = "attachment; filename=#{key}"
          headers[:content_type] = "text/csv"
        when :pdf
          headers[:content_type] = "application/pdf"
        end
      end

      # generates signed_url for private objects
      # TODO: move default expiration to config
      def signed_url(key, expiration = 900)
        signer = Aws::S3::Presigner.new(client: s3_client)
        signer.presigned_url(:get_object,
                             bucket: bucket,
                             key: key,
                             expires_in: expiration)
      end

      def blank?(val)
        val.nil? || val.to_s == ""
      end
    end
  end
end
