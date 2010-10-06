
module DummyServerHelper
  
  DEFAULT_PORT = EM_GNTP::Dummy::Server::DEFAULT_PORT
  
  def self.fork_server(opts = {})
    fork {
      puts '-------------- server process fork ------------------'
      EM_GNTP::Dummy::Server.reset_canned_responses
      if opts[:register]
        EM_GNTP::Dummy::Server.respond_to_register_with *opts[:register]
      end
      if opts[:notify]
        EM_GNTP::Dummy::Server.respond_to_notify_with *opts[:notify]
      end
      if opts[:callback]
        EM_GNTP::Dummy::Server.callback_with *opts[:callback]
      end
      EM.run {
        Signal.trap("INT") { EM.next_tick { EM.stop } }
        EM_GNTP::Dummy::Server.listen
      }
      puts '-------------- server process exiting -----------'
    }    
  end
  
  def self.kill_server(pid)
    Process.kill("INT", pid)
  end
  
end
