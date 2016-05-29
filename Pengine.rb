
# # Copyright (c) 2016 Simularity Inc.
require 'json'
require 'net/http'

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
  po = nil
  attr_reader: id
  attr_reader: state
  attr_reader: current_query
  attr_reader: slave_limit
  avail_output

  def initialize(builder)
    @po = builder.clone
    @state = new PengineState
    @current_query = nil
    @slave_limit = -1
    @avail_output = []
    @id = create
    if(@id == nil)
      @state.destroy
  end

  def isDestroyed
    return state.isIn(:destroyed)
  end

  penginePost(
    url,
    contentType,
    body
    )
    uri = URI(url)
    req = Net::HTTP::Post.new(uri)
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
      // TODO figure out how to handle errors
      res.value
    end
  end

  create(po)
    state.must_be_in(:not_created)

    resp = penginePost(
      po.getActualURL('create'),
      'application/json',
      po.getRequestBodyCreate)

    if(resp.has_key?(:slave_limit))
      @slave_limit = Integer(resp['slave_limit'])

    event = resp[:event]

    case event
    when 'destroy'
      state.setState(:destroyed)
    when 'create'
      state.setState(:idle)
    else
      puts "event is illegal value #{event}"
    end

    if(po.hasAsk())
      @current_query = new Query(this, po.getAsk(), false)

    if(resp.has_key?('answer'))
      handleAnswer(resp[:answer])

    id = resp[:id]

    return id;
  end

  handleAnswer(answer)
    if(answer.has_key?(:event))
      case answer[:event]
      when 'success'
        if(answer.has_key?(:data))
          @current_query.addNewData(answer[:data])
        end

        if(answer.has_key?(:more))
          if(answer[:more] == 'false')
            @current_query.noMore()
          end
        end
      when 'destroy'
        if(answer.has_key?(:data))
          handleAnswer(answer[:data])
        end

        if(@current_query != nil)
          @current_query.noMore()
        end

        @state.setState(:destroyed)
      when 'failure'
        @current_query.noMore()
      when 'error'
        raise 'Syntax error - probably invalid Prolog query'
      when 'output'
        @avail_output << answer[:data]
      when 'died'
        @state.setState(:destroyed)
      else
        raise "Bad event #{answer[:event]}in answer"
      end
    end
  end

  dumpStateDebug
    puts "#{@id} #{slave_limit}\n"
    if(@current_query != nil)
      current_query.dumpDebugState
    end

    @po.dumpDebugState
    @state.dumpDebugState
  end

  


end
