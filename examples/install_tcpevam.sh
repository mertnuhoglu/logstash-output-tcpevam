cd ..
gem build logstash-output-tcpevam.gemspec
/Users/mertnuhoglu/projects/tools/logstash-1.5.4/bin/plugin install /Users/mertnuhoglu/projects/ruby/logstash_plugins/logstash-output-tcpevam/logstash-output-tcpevam-2.0.2.gem
cd examples
/Users/mertnuhoglu/projects/tools/logstash-1.5.4/bin/logstash -f $1
