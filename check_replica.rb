require 'aws-sdk'
require 'mysql2'

# ENV NEED:
#  ENV['AWS_REGION']
#  ENV['BDASH_OPT_DB_HOST']
#  ENV['BDASH_OPT_DB_USERNAME']
#  ENV['BDASH_OPT_DB_PASSWORD']
#  ENV['BDASH_OPT_DB_NAME']

ret = ""
min_value = 100000

rds = Aws::RDS::Client.new(region: ENV['AWS_REGION'])
resp = rds.describe_db_instances
resp.db_instances.each do |r|
  if r.endpoint != nil and r.endpoint.address == ENV['BDASH_OPT_DB_HOST'] then
    replicas = r.read_replica_db_instance_identifiers
    unless replicas.empty?
      replicas.each do |x|
        res1 = rds.describe_db_instances({db_instance_identifier: x})
        if res1.db_instances.size >= 1 and res1.db_instances[0].endpoint != nil then
          addr = res1.db_instances[0].endpoint.address
          port = res1.db_instances[0].endpoint.port
          my = Mysql2::Client.new(:host=> addr, :port=>port, :username=> ENV['BDASH_OPT_DB_USERNAME'], :password=>ENV['BDASH_OPT_DB_PASSWORD'], :database=> ENV['BDASH_OPT_DB_NAME'])
          res = my.query("show status like 'Threads_connected'")
          res.each do |row|
            if min_value > row["Value"].to_i
              min_value = row["Value"].to_i
              ret = "#{addr}:#{port}"
            end
          end
          my.close
        end
      end
    end
  end
end

return ret
