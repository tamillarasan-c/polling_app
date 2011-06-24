class WebsocketsController < Cramp::Websocket  
  self.backend="thin"

  on_data :start_polling
  on_finish :stop_polling
 
  def start_polling(message)
    @thread_id=message    
    @timer=EM::PeriodicTimer.new(1) { update_status }
  end

  def update_status    
    render $redis.get "#{@thread_id}:status"      
  end  
  
  def stop_polling
    @timer.cancel
  end
end
