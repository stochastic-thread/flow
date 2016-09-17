use Mix.Config

config :flow,
  service_url: "ws.pusherapp.com",
  path: "/app/de504dc5763aeef9ff52?client=js&version=3.0&protocol=5",
  elastic_ip: "127.0.0.1",
  elastic_port: "9200",
  index_name: "bitstamp",
  type_name: "diff_order_book",
  log_name: "log_ts.txt"
