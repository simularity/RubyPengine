# rubypengines

A Ruby language client for Torbjörn Lager's _Pengines_ distributed computing library for
_[SWI-Prolog](http://swi-prolog.org)_ .

RubyPengines is a Ruby language implementation of the _Pengines_ protocol, a lightweight, powerful query and update protocol for a _Pengines_ server.

Pengines servers dramatically reduce the complexity of performing RPC and sharing _knowledge_ in a mixed technology environment. They can act effectively as 'glue' in a complex system.

Currently there are clients for 

 * RubyScript (in browser), 
 * nodejs [By okcomputer](https://www.npmjs.com/package/pengines)
 * SWI-Prolog [Pengines documentation](http://www.swi-prolog.org/pldoc/man?section=pengine-overview)
 * Java [also by Simularity](https://github.com/simularity/JavaPengine)
 * Ruby (what you're reading)

The query language for Pengines is _Prolog_, and so unsurprisingly, the only current implementation of the Pengines server ships with the _[SWI-Prolog](http://swi-prolog.org)_ environment. SWI-Prolog is probably the most widely used implementation of Prolog, particularly suitable for large _real world_ projects.

## Installation

You will need the json gem

gem install json

Put these files on your source path somewhere


## Understanding RubyPengine

RubyPengine is a thin wrapper around [http://pengines.swi-prolog.org/docs/index.html](Pengines), and so use requires knowledge of the Pengines system, although only minimal understanding of pengines or of Prolog is sufficient to make basic queries.

The Pengine architecture is simple. The client requests the server to create a Pengine _slave_. The client then sends one or more queries to the slave, and then tells the server to destroy the pengine.

For efficiency, a query can be sent along with the create query. The pengine can be told to destroy itself at the end of the first query. So a Pengine can be created, queried, and destroyed in as little as a single HTTP request.

The queries are simply Prolog code. So the entire power of the Prolog language is available to the client.

Obviously the Pengine server must _sandbox_ the query. So some Prolog library predicates (e.g. shell) are unavailable. But, as much as is consistent with security, the standard Prolog libraries are available to the Pengine slave.

Additionally, Pengine servers usually expose some special predicates (Prolog 'functions' are called predicates). So, for example, a Prolog server could expose a predicate that allows a user to set their profile (presumably also passing some authentication).

Because the Pengine can last longer than one query, the client can store information on the server between queries. This can significantly reduce network traffic during complex graph queries.

### The Pengines Architecture

Unlike imperative programs, in Prolog one constructs a "knowledgebase" of rules about a world, and then asks the system to find proofs of propositions, called queries. So there are two parts to a Prolog program - the rules, and the query.

Pengines extends SWI-Prolog to provide a distributed computing environment. Pengines exposes an HTTP based protocol that allows a remote system to submit queries and even alter the knowledgebase.

This is not unlike how web servers supply Javascript to the browser to execute, with the client in role of the server and the pengine server in role of the web browser.

Each created pengine creates, effectively, it's own Prolog sub-VM. Different pengine slaves see different knowledgebases. 

The pengine's knowledgebase is a combination of what the server chooses to expose, and what the client supplies. The server supplied part includes the safe parts of the standard Prolog libraries. 

For a complete explanation of this process, watch [https://www.youtube.com/watch?v=JmOHV5IlPyU](my video from Strange Loop)

This provides lots of benefits. The remote client has a full, Turing complete language available for writing queries. Need some complex natural language scoring function computed to decide whether you need that row of data? Do it on the server.

The remote client can also store data on the server between invocations. Need to hang onto an intermediate stage query? Leave it on the server. Need to do graph traversal looking things? Do it on the server. Have a really complicated query you don't want to transmit for each query? Leave the code for it on the server.

### Life Cycle

A slave pengine is created, used for zero or more queries, and then destroyed, either explicitly or by timing out.
A common, but not universal, pattern is to create a pengine, query it once, then destroy it. So RubyPengine supports this by allowing you to just make a query and repeatedly ask for the answers.

Making a Pengine for a single query is so common that it is the default for PengineBuilder. To retain the Pengine you must `destroy = false` on the PengineBuilder.

Prolog queries may return a single answer, but they can also fail (return no answer) or return many answers. This is fundamental to the SLD resolution mechanism at the core of Prolog.

In it's most basic use, the pengines protocol requires one HTTP request to create the pengine, one to initiate a query and get the first answer, one for each answer thereafter, and one to destroy the pengine.

But the pengines protocol allows the client to send the first query with the create message. This saves an HTTP round trip. The protocol also contains a flag that says 'destroy this pengine at the end of the first query'. This saves another round trip.  For a pengine that is used for a single deterministic query, this reduces the number of HTTP requests from 3 to 1, a factor of 3 reduction in network traffic.

### Slave Limit

Pengine servers have a per-client slave limit. Clients must destroy pengines before making new ones to stay under the limit.

## API
---

Making a Pengine starts with `PengineBuilder`. 

Make a  new PengineBuilder object, set some attributes on it, and then user it to make one or more Pengines.

the `destroy` attribute is particularly important to set. By default it's true, and when the first query done on the pengine has returned it's last result, the pengine destroys itself.

Some arguments to create a Pengine change with each Pengine, like ask. Some are usually constant, like the server's name. It can be useful to have a prototype PengineBuilder around and clone it, then change values on the clone before making the Pengine.

Pass the PengineBuilder to the Pengine constructor to get a new Pengine.

If you supplied an ask to the PengineBuilder via the `ask` attribute, the Pengine will already be executing a query. You can get the query via `current_query`.

If not, you'll need to start a query with `ask('some_prolog_goes_here')`.

Both of these return a `Query` object.

if the `hasNext()` method returns true, the query _may_ have more answers. `next()` returns the next Proof, or nil if there are none.

The Proof object is a hash that maps variables in the query to values. So 

---
    member(X, [a,b,c])
---

would result in `{ "X": "a"}` as the first proof, `{ "X": "b"}` as the second, and `{ "X": "c"}` as the last.

If you want to stop getting solutions before they're exhausted, Query has a `stop` method.

After you have stopped or exhausted the solutions, you can start another query. Each Pengine can be used for only one query at a time.

When you are done with the Pengine, call `Pengine::destroy` on it. This will happen automatically if you left destroy set to true.

## Don't Know Prolog

If you don't know Prolog, you can do most basic queries with this introduction.

### Atoms and Variables

Prolog is case sensitive. Variables start with an uppercase letter, so ThisIsAVariable. All other identifiers are atoms, which either start
with a lowercase letter, and consist of letters, numbers, and underscore: this_is_an_atom, or are enclosed in single quotes: '!Wow, also an atom!'.  `'taxes'` and `taxes` are the same atom - the single quotes are optional here.

### Queries

Most pengines queries are simply a call to a single predicate (sort of like a function in Prolog). 

---
    employee_info('Bob Smith', Position, Salary)
---

The results will *bind* Position and Salary to whatever's appropriate for Bob.  This means we can ask strange questions like
who has a salary of 85000.

---
    employee_info(Name, Position, 85000)
---

It's up to the implementer on the Prolog side which of of these 'modes' are actually implemented. You'll need to check with the documentation of the Prolog code. A commonly used convention in the Prolog community is to write a + meaning the argument must be supplied, a - to mean the predicate will fill it in, and ? to mean either is acceptable.  So, we can probably ask for any combination of arguments for employee_info. This would be documented as employee_info(?, ?, ?).


### Underscore

We really didn't ask for the position, we just wanted the name. So we can put an underscore in the second argument to say we're not interested in it.

---
    employee_info(Name, _, 85000)
---


### Strings

Notice that Bob's name is an atom.  Prolog also has "real strings", and "codes strings". All get converted to Ruby Strings.

### Nondeterminism

Now, if we happen to have two Bob Smiths in the company?  We'll get two rows of data. If there is no Bob Smith, we'll get no data. So Queries always return an iterator.

One tricky bit about this.  Prolog returns all the ways it can 'prove' the employee info is true. This sometimes means it will return multiple copies of a single answer. If you need rows to be distinct, work with the Prolog programmer.

### Limiting answers

I said above that most queries are a single predicate. An exception to that is that you might want to limit your query to a range. Here's how to do it.

---
    (employee_info(Name, _, Salary), Salary > 85000, Salary =< 120000)
---

The commas mean 'and' in this context. You can use another predicate as well. Say you have +department(Name, Department)+ and want to find salaries of employees in marketing.

---
    (employee_info(Name, _, Salary), department(Name, marketing))
---

Notice, as an aside, that marketing is an atom. 



## License

Copyright (c) 2016 Simularity Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.


