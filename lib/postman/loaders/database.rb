class MailQueue
  include DataMapper::Resource

  property :id, Serial
  property :priority, Enum[:urgent, :normal, :low]
  property :to_email, String, :length => 255, :required => true
  property :to_name, String, :length => 255
  property :from_email, String, :length => 255, :required => true
  property :from_name, String, :length => 255
  property :subject, String, :length => 255
  property :body, Text
end

module Postman
  class Database

    def initialize(sources)
      DataMapper::Logger.new(STDOUT, 'fatal')

      raise ArgumentError, 'One of the database names must be default' unless sources.include?('default')
      sources.each_pair do |name, opts|
        DataMapper.setup(name.to_sym, opts)
      end

      DataMapper.finalize
    end

    def find_emails(priority, quota)
      emails = []
      Postman.configuration.databases.each_key do |database|
        new_emails = DataMapper.repository(database.to_sym) {MailQueue.all(:priority => priority, :limit => quota)}
        quota -= new_emails.size
        emails.concat(new_emails)
      end
      emails
    end

    def delete(email)
      email.destroy
    end
  end
end
