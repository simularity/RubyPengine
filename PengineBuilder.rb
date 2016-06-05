
require 'json'
# # Copyright (c) 2016 Simularity Inc.
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

class PengineBuilder
  attr_accessor :server
  attr_accessor :application
  attr_accessor :ask
  attr_accessor :chunk
  attr_accessor :destroy
  attr_accessor :srctext
  attr_reader :format
  attr_accessor :pengine_alias

  # Create the object
  def initialize(
    server,
    application = "sandbox",
    ask = nil,
    chunk = 1,
    destroy = true,
    srctext = nil,
    pengine_alias = nil)

    @server = server
    @application = application
    @ask = ask
    @chunk = chunk
    @destroy = destroy
    @srctext = srctext
    @format = "json"
    @pengine_alias = pengine_alias
  end

  # Internal method for package
  def getActualURL(action)
    if @server.end_with? "/"
      return @server << action
    else
      return @server << "/" << action
    end
  end

  def getActualURLid(action, id)
    if @server.end_with? "/"
      return @server << action << "?format=json&id=" << URI.encode(id)
    else
      return @server << "/" << action << "?format=json&id=" << URI.encode(id)
    end
  end

  def getRequestBodyCreate
    #  JSON.dump(hash)
    h = { :format => "json",
          :destroy => @destroy }

    if(@chunk > 1)
      h.store(:chunk, @chunk)
    end

    if(@srctext != nil)
      h.store(:srctext, @srctext)
    end

    if(@srcurl != nil)
      h.store(:srcurl, @srcurl)
    end

    if(@ask != nil)
      h.store(:ask, @ask)
    end

    return   JSON.dump(h)
  end

  def getRequestBodyAsk(id, ask)
    return "ask(#{ask}, [])."
  end

  def newPengine
    return Pengine.new(self)
  end

  def getRequestBodyNext
    return "next."
  end

  def getRequestBodyDestroy
    return "destroy."
  end

  def getRequestBodyStop
    return "stop."
  end

  def getRequestBodyPullResponse
    return "pull_response."
  end

  def hasAsk
    return @ask != nil
  end

  def removeAsk
    @ask = nil
  end
end
