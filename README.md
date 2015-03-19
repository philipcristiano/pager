# PagEr

Play with Erlang to make a stream processor.

Currently just reads from kafka and prints out messages

Create a `pager.config`

    [
     {pager, [
              {kafka_hosts, [{"hostname", 9092}]},
              {topic, <<"topic">>}
             ]}
    ].
