def import_jar
  require '/Users/mertnuhoglu/projects/ruby/logstash_plugins/filelistener_4.0.4/lib/guava-16.0.1.jar'
  b =  com.google.common.base.Optional.of(10)
  puts b.get
end

if __FILE__ == $0
  import_jar
end