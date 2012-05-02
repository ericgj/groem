
module DummyServerHelper
  
  DEFAULT_PORT = Groem::Dummy::Server::DEFAULT_PORT
  
  def self.fork_server(opts = {})
    sleep(1)

    pid = fork {
      puts '-------------- server process fork ------------------'
      Groem::Dummy::Server.reset_canned_responses
      if opts[:register]
        Groem::Dummy::Server.respond_to_register_with *opts[:register]
      end
      if opts[:notify]
        Groem::Dummy::Server.respond_to_notify_with *opts[:notify]
      end
      if opts[:callback]
        Groem::Dummy::Server.callback_with *opts[:callback]
      end
      EM.run {
        Signal.trap("INT") { EM.next_tick { EM.stop } }
        Groem::Dummy::Server.listen
      }
      puts '-------------- server process exiting -----------'
    }
    sleep(1)
    pid
  end
  
  def self.kill_server(pid)
    Process.kill("INT", pid)
    #sleep(1)
  end
  
end
