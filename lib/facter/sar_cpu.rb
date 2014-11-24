#time = Time.new
#if time.min > 30
#  start_time = "#{time.hour}:#{time.min - 30}:00"
#else
#  start_time = "#{time.hour - 1}:30:00"
#end
#
#sar_out = %x(sar -s #{start_time} -e #{time.hour}:#{time.min.to_s.rjust(2, '0')}:00|grep Average).split(/\s+/)
##fields:  Time  CPU  %user     %nice   %system   %iowait    %steal     %idle
#fields = ['idle', 'steal', 'iowait', 'system', 'nice', 'user']
#fields.each do |field|
#  Facter.add("sar_cpu_#{field}") do
#    setcode do
#      sar_out.pop
#    end
#  end
#end
