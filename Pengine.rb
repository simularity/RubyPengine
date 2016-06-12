

require 'json'
require 'net/http'
require './PengineState'

# # Copyright (c) 2016 Simularity Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

class Pengine
  attr_reader :id
  attr_reader :state
  attr_reader :current_query
  attr_reader :slave_limit

  def initialize(builder)
    @po = builder.clone
    @state = PengineState.new
    @current_query = nil
    @slave_limit = -1
    @avail_output = []
    @id = self.create()
    if(@id == nil)
      @state.destroy
    end
  end

  def isDestroyed
    return state.isIn(:destroyed)
  end

  def penginePost(
    url,                 # a string
    contentType,
    body
    )
    uri = URI::parse(url)
    req = Net::HTTP::Post.new(url)
    req.body = body
    req.content_type = contentType
    req['User-Agent'] = 'RubyPengine'
    req['Accept'] = 'application/json'
    req['Accept-Language'] = 'en-US,en;q=0.5'
    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end

    case res
    when Net::HTTPSuccess, Net::HTTPRedirection
      # OK
      result = res.body
      return(JSON.parse(result))
    else
      # TODO figure out how to handle errors
      res.value
    end
  end
  private :penginePost

# pray tell why cant I be called from initializer without
  def create
    state.must_be_in(:not_created)

    resp = penginePost(
      @po.getActualURL('create'),
      'application/json',
      @po.getRequestBodyCreate)

    if(resp.has_key?('slave_limit'))
      @slave_limit = Integer(resp['slave_limit'])
    end

    event = resp['event']

    case event
    when 'destroy'
      @state.setState(:destroyed)
    when 'create'
      @state.setState(:idle)
    else
      puts "event is illegal value #{event}"
    end

    if(@po.hasAsk())
      @current_query = Query.new(self, po.getAsk(), false)
    end

    if(resp.has_key?('answer'))
      handleAnswer(resp['answer'])
    end

    id = resp['id']

    return id;
  end

  def handleAnswer(answer)
    if(answer.has_key?('event'))
      case answer['event']
      when 'success'
        if(answer.has_key?('data'))
          @current_query.addNewData(answer['data'])
        end

        if(answer.has_key?('more'))
          if(answer['more'] == false)
            @current_query.noMore()
          end
        end
      when 'destroy'
        if(answer.has_key?('data'))
          handleAnswer(answer['data'])
        end

        if(@current_query != nil)
          @current_query.noMore()
        end

        @state.setState(:destroyed)
      when 'failure'
        @current_query.noMore()
      when 'error'
        raise "Syntax error  - probably invalid Prolog query #{answer}"
      when 'output'
        @avail_output + answer['data']
      when 'died'
        @state.setState(:destroyed)
      else
        raise "Bad event #{answer['event']}in answer"
      end
    end
  end
  private :handleAnswer

  def dumpStateDebug
    puts '*****'
    puts "#{@id} #{slave_limit}\n"
    if(@current_query != nil)
      current_query.dumpDebugState
    end

    @po.dumpDebugState
    @state.dumpDebugState
    puts '******'
  end

  def ask(query)
    @state.must_be_in(:idle)

    if(@current_query != nil)
      raise 'Have not extracted all answers from previous query (or stopped it)'
    end

    @current_query = Query.new(self, query, true)

    return @current_query
  end

  #  Actually do the pengine protocol to perform an ask
  # probably not what you want, see ask/1
  #
  # query the Query object
  # ask the prolog query
  def doAsk(query, ask)
    @state.must_be_in(:idle)

    if(@current_query == nil)
      @current_query = query
    end

    @state.setState(:ask)

    answer = penginePost(
      @po.getActualURLid('send', self.getID()),
      "application/x-prolog; charset=UTF-8",
      @po.getRequestBodyAsk(self.getID(), ask))

    handleAnswer(answer)
  end

  # signal me that the Query will not use the Pengine again
  # not what you want
  # query  the Query that has finished
  def iAmFinished(query)
    if(query == @current_query)
      @current_query = nil
    end

    if(@state == :ask)
      @state.setState(:idle)
    end
  end

  #  Actually do the pengine protocol to perform a next
  # probably not what you want, see ask/1
  #
  # query the Query object
  def doNext(query)
    @state.must_be_in(:ask)

    if(@current_query != query)
      raise "Cannot advance more than one query - finish one before starting next"
    end

    answer = penginePost(
      @po.getActualURLid('send', self.getID()),
      "application/x-prolog; charset=UTF-8",
      @po.getRequestBodyNext)

    handleAnswer(answer)
  end

  # return the Pengine ID. Rarely needed.
  def getID
    @state.must_be_in_2(:ask, :idle)

    return @id
  end

  # Destroy this pengine
  def destroy
    if(@state.isIn(:destroyed))
      return
    end

    @state.must_be_in_2(:ask, :idle)

    begin
      answer = penginePost(
        @po.getActualURLid('send', self.getID()),
        "application/x-prolog; charset=UTF-8",
        @po.getRequestBodyDestroy)

      handleAnswer(answer)
    ensure
      @state.destroy
    end
  end

  # low level protocol to support stop
  # probably not what you want
  def doStop
    @state.must_be_in(:ask)

    answer = penginePost(
      @po.getActualURLid('send', self.getID()),
      "application/x-prolog; charset=UTF-8",
      @po.getRequestBodyNext)

    handleAnswer(answer)
  end


  # low level protocol to support pull_response
  # probably not what you want
  def doPullResponse
    if(!@state.isIn(:ask) && !@state.isIn(:idle))
      return
    end

    answer = penginePost(
      @po.getActualURLid('pull_response', self.getID()),
      "application/x-prolog; charset=UTF-8",
      @po.getRequestBodyPullResponse)

    handleAnswer(answer)
  end

   # return one piece of pending output, if any.
   # If it doesn't have any to return, it returns null
  
   # @deprecated If you call it when the pengine's not got output it opens a connection that never closes, 
   # so using this is definitely not recommended

   # @return  output string from slave, or null
  def getOutput
    if(!@avail_output.empty?)
      return @avail_output.delete_at(0)
    end

    if(@state.isIn(:ask) || @state.isIn(:idle))
      self.doPullResponse
    end

    if(!@avail_output.empty?)
      return @avail_output.delete_at(0)
    end

    return nil  
  end
end


