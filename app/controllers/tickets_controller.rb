class TicketsController < ApplicationController

  def index
    session[:page]=nil
  end
  
  def new    
    session[:search_thread_id] = nil
    session[:page]=params[:page]
    @search_status = Ticket::SEARCH_STATUS_START
  end  

  def search
    if session[:search_thread_id].nil?
      session[:search_thread_id] = start_searching      
    else    
      @search_status = ($redis.get "#{session[:search_thread_id]}:status").to_f      
      respond_to do |format|          
        format.js { render :partial => "tickets/status_ajax" }
        format.html {render :action => "result" if @search_status >= Ticket::SEARCH_STATUS_COMPLETE }
      end
    end
  end
  
  def result
    
  end

  private
  
  def start_searching
    search_thread = Thread.new {
      redis=Redis.new
      (0..Ticket::SEARCH_TIME).each do |search_time|
        percentage_complete = (search_time/Ticket::SEARCH_TIME) * Ticket::SEARCH_STATUS_COMPLETE
        redis.set "#{Thread.current.object_id}:status", percentage_complete
        sleep 1
      end
    }  
    search_thread.object_id
  end  
end
