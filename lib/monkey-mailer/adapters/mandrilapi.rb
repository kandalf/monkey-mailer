require "net/http"
require "uri"
require "json"
require 'base64'

module MonkeyMailer
  module Adapters
    class MandrilAPI
      @key = ''
      @request = {}
      @uri = ''

      ENDPOINT = 'https://mandrillapp.com/api/1.0'

      def initialize(options)
        @key = options[:mandril_api_key]
        @request = Hash.new
        @uri = URI.parse(URI.encode(ENDPOINT))
      end

      def send_email(email)

        @request = {
          :key => '',
          :message => {
            :html => '',
            :text => '',
            :subject => '',
            :from_email => '',
            :from_name => '',
            :to => [],
            :headers => {},
            :track_opens => true,
            :track_clicks => true,
            :auto_text => true,
            :url_strip_qs => true,
            :preserve_recipients => false,
            :bcc_address => '',
            :attachments => []
          },
          :async => true
        }

        @request[:key] = @key
        @request[:message][:to] << { :email => email.to_email, :name => email.to_name}
        @request[:message][:from_name] = email.from_name
        @request[:message][:from_email] = email.from_email
        @request[:message][:html] = email.body
        @request[:message][:text] = email.body.gsub(/<\/?[^>]*>/, "") unless email.body.nil?
        @request[:message][:subject] = email.subject

        email.attachments.each do |attachment|
          @request[:message][:attachments] << {
            :type => attachment.content_type,
            :name => File.basename(attachment.file_path),
            :content => Base64.encode64(File.read(attachment.file_path))
          }
        end


        req = Net::HTTP::Post.new('/api/1.0/messages/send.json', initheader = {'Content-Type' =>'application/json'})
        req.body = @request.to_json

        http = Net::HTTP.new(@uri.host, @uri.port)
        http.use_ssl = true
        response = http.start {|http| http.request(req)}
        raise MonkeyMailer::DeliverError.new("Mandril response.code not equal to 200") unless response.code.to_i == 200
        puts "Response #{response.code} #{response.message}: #{response.body}"
      end
    end
  end
end
