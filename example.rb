#~/usr/bin/env ruby -w

require './PengineBuilder'
require './Pengine'
require './Query'

# # Copyright (c) 2016 Simularity Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

if __FILE__ == $0
	po = PengineBuilder.new('http://localhost:9900/')

	

	p = po.newPengine

	q = p.ask('member(X, [a,b,c])')

	while(q.hasNext())
		answer = q.next 
		if(answer != nil)
			puts answer
		end
	end

	p = po.newPengine
	q = p.ask('member(X, [a(taco),2,c])')

	while(q.hasNext())
		answer = q.next 
		if(answer != nil)
			puts answer
		end
	end

	po.destroy = false
	p = po.newPengine
	q = p.ask('member(X, [d,e,f])')

	while(q.hasNext())
		answer = q.next 
		if(answer != nil)
			puts answer
		end
	end

	q = p.ask('member(X, [g,h,i])')

	while(q.hasNext())
		answer = q.next 
		if(answer != nil)
			puts answer
		end
	end

	p.destroy

	begin
		q = p.ask('member(X, [w,x,y])')
	rescue Object
		puts "should be 'Pengine not in state idle, is in destroyed' " + $!.to_s
	end

	po.chunk = 3
	po.destroy = true

	p = po.newPengine

	q = p.ask('member(X, [a,b,c,d,e])')

	while(q.hasNext())
		answer = q.next 
		if(answer != nil)
			puts answer
		end
	end

	po.destroy = false

	p = po.newPengine

	q = p.ask('member(X, [a,b,c,d,e,f])')

	while(q.hasNext())
		answer = q.next 
		if(answer != nil)
			puts answer
		end
	end

	q = p.ask('member(X, [g,h,i,j,k])')

	while(q.hasNext())
		answer = q.next 
		if(answer != nil)
			puts answer
		end
	end

	p.destroy 

	po.destroy = false

	n = 0
	while(n < 5)
		n = n + 1

		p = po.newPengine

		q = p.ask('member(X, [a,b,c,d,e,f])')

		i = 4
		while(q.hasNext() && i < 5)
			answer = q.next 
			i = i + 1
			if(answer != nil)
				puts answer
			end
		end	

		begin
			q = p.ask('length([a,b,c], X)')
		rescue Object
			puts "should be ' Pengine not in state idle, is in ask' " + $!.to_s
		end
	end

	p.destroy 

# the most efficient way
	po.destroy = true
	po.ask = 'member(X, [a,b,c,d,e,f])'

	p = po.newPengine

	q = p.current_query

	while(q.hasNext())
		answer = q.next 
		if(answer != nil)
			puts answer
		end
	end

# TODO test stop

end