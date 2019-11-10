# strictly-logic
Perl scripts for setting up a website based on a network of user-entered logical statements

## What is strictly-logic?
The idea is that there is a website where people go and enter if-then statements and votes on whether it is true, not always true, or unknown/unanswerable - this is the "voted" status.  The site records these statements and checks them for logical inconsistencies with other statements previously entered by other users, and gives it (and other statements) an "implied" status based on the voted status of any related statements in the network.  It also creates its own if-then statements (using user-created statements to provide the "if" and "then" separately) that logically follow from what has already been entered.

The system also auto-generates pages for the statements that can be used for voting.

Strictly logic is *not* an expert system.  The goal is to enable users to collaborate to find their own answers rather than to provide them.

## Does it work yet?
Sort of - what might be called a working alpha/beta/etc is at http://www.strictlylogic.com .  Unfortunately there are known bugs, and the system is far from user-friendly.

## What are these files?
I've committed what's basically the cgi-bin of the live site, which contains everything needed to make the system work, other than a database.  Which you'd have to set up manually by guessing/figuring out the right table structure.  Right now there's no autogenerate for it because I anticipate zero immediate interesting in anyone making their own version of this thing.

##### .pl files -
- createprinciple.pl - this is the entry point for users creating new logical principles
- search.pl - users can go here to search existing statements
- votehandler.pl - handles the voting system to determine if principles are true/false/unknown 

##### .pm "objects"
I created certain modules to represent objects, and these correspond to tables.  These are:
- conclusion.pm - this is basically an if-then combined.  Some comments/variables in the code may use "conclusion" to mean the then part only.  Sorry.
- dependency.pm - I only vaguely remember the point of this and I think it's used to link conclusions for generating pages, and it might be entirely useless but is still needed for compiling at the moment.
- ioshift.pm, ioshiftvalue.pm, ioshiftvar.pm, iovarposition.pm, premisevar.pm, premisevarposition.pm - These objects all are used to track how variables are used within statements (iostatements) and match them together with principles that use the variables differently. (e.g. we want to be able to match "if @1 > @2 then @2 < @1" with "if @1 < @2 then ~@2 >= @1" to make "if @1 > @2 then ~@2 >= @1" . Unfortunately at the moment while this case works, the implication handler also creates some illogical principles when processing it).
- iostatements.pm - these represent statements independent of the variables.  So just the if part (or one of them) or just the then part of a principle.
- premise.pm - a premise also represents the individual if part(s) and then part, but unlike iostatements is specifically one tied to a particular conclusion (and with particular variables)
- transitive.pm - see dependency.pm

##### Logic modules
- implicationhandler.pm - this is the central module that does the logic for creating auto-generated principles.  It calls four rules, represented by conjunction.pm, contrapositive.pm, then2.pm, and transitiveimplication.pm.  The whole system is based very loosely on [the Wikipedia article on Frege's Begriffsschrift](https://en.wikipedia.org/wiki/Begriffsschrift) which I don't claim to fully understand.
- truthstatusupdater.pm - this handles the "implied" truth of statements using modus ponens and modus tollens.
- linkfinder.pm - this contains methods to find stuff in the database that's key for keeping the logic in the above rule modules short and understandable.

##### Other
- createstatementpage.pm - creates the page for each principle that's used for voting
- createtransitivedetail.pm - not used at the moment, see note on this file.
Other files in the repository are utilities for different things, probably.

## Where can I find out more?  
Development blog is at http://www.strictlylogic.com/slblog .  This also includes more about the logical theory behind it to the extent there is one.  It's updated almost annually.
