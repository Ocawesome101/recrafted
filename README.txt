                     RECRAFTED

Recrafted is ComputerCraft's CraftOS but with saner
API design.  It's also not licensed under the CCPL,
but rather the MIT license -- so you can freely use
Recrafted's  code in  other projects  without being
legally  bound  to  license  them  under  the CCPL.

All  APIs  are  implemented  as  described  on  the
CC: Tweaked wiki at https://tweaked.cc, with slight
modifications   to  fit  Recrafted's   API  design.
None of  Recrafted's  code is  taken from  CraftOS.


Recrafted addresses several  major pain points many
have with  CraftOS.  It  has  native multithreading
support (not just parallel,  but a full scheduler);
changes  to  package.path   are  fully  persistent;
os.loadAPI has been  altogether discarded;  none of
the APIs provided by  the  system are inserted into
_G at  boot--instead  they  must  be  loaded  using
require(), as per Lua convention.   And, of course,
the pesky CCPL is no longer present.
