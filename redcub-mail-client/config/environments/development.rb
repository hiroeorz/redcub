Merb.logger.info("Loaded DEVELOPMENT Environment...")
Merb::Config.use { |c|
  c[:exception_details] = true
  c[:reload_templates] = true
  c[:reload_classes] = true
  c[:reload_time] = 0.5
  c[:ignore_tampered_cookies] = true
  c[:log_auto_flush ] = true
  c[:log_level] = :debug

  c[:log_stream] = STDOUT
  c[:log_file]   = Merb.root / "log" / "development.log"
  # Or redirect logging into a file:
  # c[:log_file]  = Merb.root / "log" / "development.log"

  # UserConfigration
  c[:mailCountPerPage] = 30

  c[:pop3auth_host] = "192.168.4.64"
  c[:pop3auth_port] = 110
}
