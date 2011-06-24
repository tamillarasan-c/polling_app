require 'spec_helper'

describe TicketsController do
  render_views
  
  describe "GET 'new'" do
    it "should render the right page" do
      get "new"
      response.should be_successful
      response.should have_selector("form",:action => "search") do |form|
        form.should have_selector("input",:type => "submit")
      end      
    end   
  end

  describe "Request for search" do
    before(:each) do
      session[:search_thread_id] = nil
    end
    
    describe "using post" do   
      it "should start the search" do
        controller.should_receive(:start_searching).and_return(1)        
        post :search
        session[:search_thread_id].should ==1
      end
      
      it "should render the search progress page" do
        post :search
        response.should render_template "search"
      end
    end
  end

  describe "During search process" do
    before(:each) do
      $redis=mock("redis-server",:nil_object => true)
      session[:search_thread_id]="1"
    end
    
    describe "post request" do
      it "should set the search status" do
        $redis.should_receive(:get).with("1:status").and_return(10)
        post :search        
        assigns[:search_status].should == 10
      end
      
      it "should redirect to result page when search is complete" do
        $redis.should_receive(:get).with("1:status").and_return(100)
        post :search
        response.should render_template "result"
      end
    end
    
    describe "ajax request" do
      it "should set the search status" do
        $redis.should_receive(:get).with("1:status").and_return(10)
        xhr :post,:search        
        assigns[:search_status].should == 10
      end
      
      it "should redirect to result page when search is complete" do
        $redis.should_receive(:get).with("1:status").and_return(100)
        xhr :post, :search
        response.should be_success
        response.should render_template "tickets/_status_ajax"
      end
    end
  end

  describe "Result action" do
    it "should render the result page" do
      get "result"
      response.should be_successful
      response.should render_template "result"
    end      
  end

  describe "start_searching function" do
    it "should create new search Thread" do
      session[:search_thread_id]=nil
      post :search
      session[:search_thread_id].should_not be_blank
      ObjectSpace._id2ref(session[:search_thread_id]).class.should == Thread
    end
    
    describe "Search Thread" do
      it "should update redis server with status" do
        redis=mock("Redis",:nil_object => true)        
        redis.should_receive(:set).with(kind_of(String),kind_of(Float)).exactly((0..Ticket::SEARCH_TIME).count)
        Redis.should_receive(:new).and_return(redis)
        session[:search_thread_id]=nil
        post :search
        ObjectSpace._id2ref(session[:search_thread_id]).join
        #Thread.list.find() {|thr| thr.object_id==session[:search_thread_id]}.join
      end
    end
  end
end

