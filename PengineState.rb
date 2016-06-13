
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
# internally used class representing the state of a Pengine

class PengineState

	attr_reader :state

	def initialize
		@state = :not_created
	end

	def ==(other)
		if(other.is_a?(Symbol))
			return other == @state
		end

		if(!other.is_a?(PengineState))
			return false
		end

		return (other.state == @state)
	end

	def isIn(aState)
		return self == aState
	end

	def must_be_in(aState)
		if(!(self == aState)) # make sure it's the override
			raise "Pengine not in state #{aState}, is in #{@state}"
		end
	end

	def must_be_in_2(aState, bState)
		if(!(self == aState) && !(self == bState)) # make sure it's the override
			raise "Pengine not in state #{aState} or #{bState}, is in #{@state}"
		end
	end

	def setState(newState)
		if(self == newState)
			return
		end

		if(
			(@state == :not_created && (newState == :idle || newState == :ask || newState == :destroyed)) ||
			(@state == :idle && (newState == :ask || newState == :destroyed)) ||
			(@state == :ask && (newState == :idle || newState == :destroyed))
			)
			@state = newState
		else
			raise "illegal state transition from #{@state} to #{newState}"
		end
	end

	def dumpDebugState
		puts @state
	end

	def destroy
		@state = :destroyed
	end
end