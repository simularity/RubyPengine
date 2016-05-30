#
# internally used class representing the state of a Pengine

class PengineState

	attr_read: state

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

	def must_be_in(aState, bState)
		if(!(self == aState) && !(self == bState)) # make sure it's the override
			raise "Pengine not in state #{aState} or #{bState}, is in #{@state}"
		end
	end

end