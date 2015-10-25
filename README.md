# TcpEvam Logstash Output Plugin

This is a plugin for [Logstash](https://github.com/elastic/logstash).

It is fully free and fully open source. The license is Apache 2.0, meaning you are pretty much free to use it however you want in whatever way.

## Installation

First, you need to install this plugin into the Logstash. Open a terminal and go to the root directory of Logstash software. Run the following command:

	bin/plugin install /path/to/logstash-output-tcpevam-2.0.2.gem

Note that, this plugin is designed to be used together with logstash-codec-evam plugin. Please, install it first from https://github.com/mertnuhoglu/logstash-codec-evam. 

## Running Examples

You can find some example logstash `conf` files to run under `examples/` directory. 

- `evam11.conf` is for testing a json input data using EvamListener.jar service

### Updating Paths

Before running example configuration files, you need to update the paths inside them. Logstash configuration files expect absolute paths. Change path parameters such as the following in these `conf` files according to your own path:

	path => ["/Users/mertnuhoglu/projects/ruby/logstash_plugins/logstash-output-tcpevam/examples/json.log"]

### Properties Configuration of EvamListener.jar

The configuration of EvamListener.jar has to be defined in a properties file. An example properties file can be seen in `examples/fileListenerAgent0.properties`.

You need to define the absolute path to this properties file inside the `conf` file as shown in this example:

  tcpevam {
		dependent_jar_path => '/Users/mertnuhoglu/projects/ruby/logstash_plugins/logstash-output-tcpevam/jars'
		hosts => [ "localhost:8888", "localhost:8889" ]
		codec => evam{
			scenario => 'scenario_type'
			event => 'event_type'
			actor => 'city.actor'
		}
  } 

## Evam Server Host Parameters

You need to specify the addresses and ports of Evam Servers using `hosts` parameter as show in the above example.

## Dependent Jar Files

This plugin depends on the following jar files: netty, log4j, listener-tokenizer, listener-parser, legacy-listener, guava, commons-utils, commons-sdk, commons-pool, commons-lang, commons-event-sender, commons-collections, commons-cli.

These jar files need to be put into a directory and the path to this directory have to be defined in `dependent_jar_path` parameter of `tcpevam` plugin as shown in the example `conf` file.

### Running netcat tcp server

To test this plugin and configuration you don't have to have Evam server installed already. You can run a test using an echoing tcp server. In order to run a simple echo tcp server on your computer, you can use netcat. If you are on osx, you can install netcat by `brew install netcat`.

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

Now, you can run `evam11.conf` to test the plugin.

Run the following commands from the root directory of Logstash:

	bin/logstash -f /path/to/evam11.conf

After a while, you will see "Logstash startup completed" message. Now, open the example input data files (`json.log`), make some changes, and save the files. 

Logstash will process input data and output the results according to `evam event format`. Check both logstash' shell (the shell where you have run logstash) and netcat shell. Both shells will print the output.

### Verifying the Outputs of Examples

Example `conf` files, expect to output to four destinations:

- TCP server
- Standard output
- Elastic search server
- File

## Additional Information

### Test Data Source

In real use cases, you will use whatever input data source you have.

In the above example `conf` files, the input data files are scanned from beginning each time they are updated. Moreover, Logstash runs the processing after input files are changed. 

