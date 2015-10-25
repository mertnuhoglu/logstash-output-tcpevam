# TcpEvam Logstash Codec Plugin

This is a plugin for [Logstash](https://github.com/elastic/logstash).

It is fully free and fully open source. The license is Apache 2.0, meaning you are pretty much free to use it however you want in whatever way.

## Installation

First, you need to install this plugin into the Logstash. Open a terminal and go to the root directory of Logstash software. Run the following command:

	bin/plugin install /path/to/logstash-codec-evam-2.0.1.gem

## Running Examples

You can find some example logstash `conf` files to run under `examples/` directory. 

- `evam07.conf` is for testing a csv input data
- `evam08.conf` is for testing a json input data

### Updating Paths

Before running example configuration files, you need to update the paths inside them. Logstash configuration files expect absolute paths. Change path parameters such as the following in these `conf` files according to your own path:

	path => ["/Users/mertnuhoglu/projects/ruby/logstash_plugins/logstash-codec-evam/examples/customer3.csv"]

### Running netcat tcp server

Above `conf` files connect and output to a tcp server. In order to run a simple echo tcp server on your computer, you can use netcat. If you are on osx, you can install netcat by `brew install netcat`.

After having installed netcat, run a tcp server on your local machine using the following command:

	netcat -l -p 8888
	
### Running elasticsearch server

The example `conf` files expect that an elasticsearch server is running on localhost. This is not a must to test evam plugin. If you don't have a running elasticsearch server, then remove the following lines from the `conf` files:

	elasticsearch {
		protocol => "http"
		host => localhost
		index => evam08
	}

### Running Logstash Example conf Files

Now, you can run `evam07.conf` or `evam08.conf`. `evam07.conf` tests csv formatted input data. `evam08.conf` tests json formatted input data.

Run the following commands from the root directory of Logstash:

	bin/logstash -f /path/to/evam07.conf
	bin/logstash -f /path/to/evam08.conf

After a while, you will see "Logstash startup completed" message. Now, open the example input data files (`customer3.csv` or `json.log`), make some changes, and save the files. 

Logstash will process input data and output the results according to `evam event format`. Check both logstash' shell (the shell where you have run logstash) and netcat shell. Both shells will print the output.

### Verifying the Outputs of Examples

Example `conf` files, expect to output to four destinations:

- TCP server
- Standard output
- Elastic search server
- File

Note that, `evam` codec is specified for `tcp` and `stdout` output plugins only. Not all output plugins handle codec parameters as expected. 

You should check each output plugin's source code whether it handles codec as expected or not. Expected behaviour is calling `encode()` function of codec plugin from `receive()` function of output plugin. 

For example, `file` output plugin doesn't call codec's `encode` function. Therefore, the output is not formatted according to the given codec. The documentation says that it calls `encode` function but source code of `file` plugin does not have such a call. If you need to use `file` output plugin with a codec, then you have two options:

- Write your own `file` output plugin
- Use `message_format` parameter of `file` plugin

## Additional Information

### Test Data Source

In real use cases, you will use whatever input data source you have.

In the above example `conf` files, the input data files are scanned from beginning each time they are updated. Moreover, Logstash runs the processing after input files are changed. 

### Actor Parameter

Evam event format expects to receive actor id of each event instance. 

In Json documents, the actor field might be a nested field. In this case, you have to specify the full path to the nested field. 

For example, this is our json document:

	{ "city" : {"actor" : "0025"}, "foo" : "s32", "bar" : {"baz" : ["a","c"]} }

Then, the path to the actor field is:

	actor => 'city.actor'

In csv files, the actor field has to be one of the columns defined in csv filter.

For example, this is the csv filter definition in `evam07.conf`:

	csv {
		columns => ["customer_id", "customer_id_high", "cslevel", "custnum", "cstype", "csactivated", "tmcode"]
		separator => ","
	}

This is the actor parameter in `evam` codec:

	actor => 'customer_id'

### Array data in Json documents

Currently, the last element of an array in Json documents are returned. For example, this is the input:

	{ "city" : {"actor" : "0025"}, "foo" : "s32", "bar" : {"baz" : ["a","c"]} }

This is the output:

	a,0025,scenario_type,event_type,city_actor,0025,foo,s32,bar_baz,c~

Note that, `c` is the last element in the array `["a","c"]`.

