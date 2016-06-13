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

class Query
	 # @param pengine the pengine that is making the query
	 # @param ask the Prolog query as a string
	 # @param queryMaster if true, set off the process to make the query on the Pengine slave.
	def initialize(pengine, ask , queryMaster)
		@hasMore = true
		@p = pengine
		@availProofs = []

		if(queryMaster)
			@p.doAsk(self, ask)
		end
	end

	def next
		if(!@availProofs.empty?)
			data = @availProofs.delete_at(0)

			if(!@hasMore && @availProofs.empty?)
				@p.iAmFinished(self)
			end

			return data
		end

		# we don't have any available proofs and the server's done
		if(!@hasMore)
			return nil
		end

		# try to get more from server
		@p.doNext(self)

		# try to get more from server
		if(!@availProofs.empty?)
			data = @availProofs.delete_at(0)

			if(!@hasMore && @availProofs.empty?)
				@p.iAmFinished(self)
			end

			return data
		end

		return nil
	end

	def noMore
		if(!@hasMore)  # must never call iAmFinished more than once
			return
		end

		@hasMore = false

		if(@availProofs.empty?)
			@p.iAmFinished(self)
		end

		# we might be held externally, waiting to deliver last Proof or no-more-Proof result
	end

  # Callback from the http world that we've got new data from the slave
  # end users shouldn't call this
	def addNewData(data)
		if(data.is_a?(Array))
			@availProofs = @availProofs + data
		else
			@availProofs.push(data)
		end
	end

	# return true if we <b>think</b> we have more data. 
	def hasNext
		return @hasMore || !@availProofs.empty?
	end

	# dump some debug information
	def dumpDebugState
		if(@hasMore)
			puts 'Has more solutions\n'
		else
			puts 'No more solutions\n'
		end

		puts "availProofs #{@availProofs}\n"
		puts "pengine #{@p.getID}"
	end

	def stop
		@p.doStop

		@hasMore = false
		@availProofs = []
		@p.iAmFinished(self)
	end
end