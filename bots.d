int[ int] foldTable, foldTableLate;
static this(){
  fwritefln( stderr, "This is PokerBots 0.03.  (c) 2006 by Manfred (Milky) Nowak");
  if( true){
    // unsuited
    for( int i= 2+13; i<= 12+13; i++) foldTable[ i*13+1]= true;
    for( int i= 3+13; i<= 12+13; i++) foldTable[ i*13+2]= true;
    for( int i= 4+13; i<= 12+13; i++) foldTable[ i*13+3]= true;
    for( int i= 5+13; i<= 12+13; i++) foldTable[ i*13+4]= true;
    for( int i= 6+13; i<= 11+13; i++) foldTable[ i*13+5]= true;
    for( int i= 9+13; i<= 11+13; i++) foldTable[ i*13+6]= true;
    // suited
    for( int i= 2   ; i<= 12   ; i++) foldTable[ i*13+1]= true;
    for( int i= 3   ; i<= 12   ; i++) foldTable[ i*13+2]= true;
    for( int i= 4   ; i<= 11   ; i++) foldTable[ i*13+3]= true;
    for( int i= 6   ; i<= 11   ; i++) foldTable[ i*13+4]= true;
    for( int i=10   ; i<= 10   ; i++) foldTable[ i*13+5]= true;
    // unsuited
    for( int i= 2+13; i<= 12+13; i++) foldTableLate[ i*13+1]= 1;
  }
}
  char answer(){
    char retval;
    bool[ char] allowed;
    allowed[ 'y']= true;
    allowed[ 'n']= true;
    allowed[ 'q']= true;
    do{
      writef( "Do you want to fold this hand? [ynq] ");
      do{
        retval= din.getc();
      } while( !isalpha( retval));
    } while( !( retval in allowed));
    if( retval == 'q') throw new Exception("Stop");;
    return retval;
  }
long round(){
  long balance= 0;
  auto talon= new Talon;
  auto visible= new Visible( talon);
  int[5] tbl;
  for( int j= 0; j<5; j++)
    tbl[ j]= visible.visible[ j+2];
  real playerVal= visible.analyze();
  Visible[ 9] other;
  for( int j= 0; j <9; j++)
    other[j] =new Visible( talon, cast(creal)1.0, tbl);
  bool otherLoose= true;
  bool otherWin= false;
  int otherSplit= 1;
  int players= 10;
  int finalPlayers= 10;
  for( int j= 0; j <9; j++){
    auto fir= other[j].visible[5]%13;
    auto sec2= other[j].visible[6]%13;
      if( other[j].visible[5]/13 != other[j].visible[6]/13) sec2+= 13;
    auto thisOneFoldsEarly= sec2*13+fir in foldTable;
    if( thisOneFoldsEarly){
      players--;
      finalPlayers--;
    } else {
            auto otherVal=other[j].analyze();
            auto thisOneFoldsLate= otherVal < 1.0;
            if( thisOneFoldsLate){
              finalPlayers--;
            } else {
              otherLoose &= playerVal > otherVal;
              otherWin |= playerVal<otherVal;
              if( playerVal==otherVal) otherSplit++;
            }
    }
  }
  char[] sorry;
  if( otherLoose) sorry= " but would have won.";
  else if( otherWin) sorry= " and did rightly so.";
       else sorry= " but the pot would have been split.";



  // you have some cards
  writefln( "\nThis is a 5/10 table. Nine more players are at the table.");
  visible.show( 5);
  writef( "%s %s in your hand. ", visible.show( 5), visible.show(6));
  if( answer() == 'n'){
    balance-= 20;
    int pot= players*20;
    writefln( "%d players remain playing. Pot contains %d.", finalPlayers, pot);
    // show flop
    writefln( "%s %s in your hand. ", visible.show( 5), visible.show(6));
    writef( "%s %s %s at the table. ",
        visible.show( 0),
        visible.show( 1),
        visible.show( 2)
      );
    if( answer() == 'n'){
      balance-= 20;
      pot+= players*20;
      writefln( "%d players remain playing. Pot contains %d.", finalPlayers, pot);
      writefln( "%s %s in your hand. ", visible.show( 5), visible.show(6));
      // show turn
      writef( "%s %s %s %s at the table. ",
        visible.show( 0),
        visible.show( 1),
        visible.show( 2),
        visible.show( 3)
      );
      if( answer() == 'n'){
        balance-= 40;
        pot+= players*40;
        writefln( "%d players remain playing. Pot contains %d.", finalPlayers, pot);
        writefln( "%s %s in your hand. ", visible.show( 5), visible.show(6));
        // show river
        writef( "%s %s %s %s %s at the table. ",
          visible.show( 0),
          visible.show( 1),
          visible.show( 2),
          visible.show( 3),
          visible.show( 4)
        );
        if( answer() == 'n'){
          balance-= 40;
          pot+= finalPlayers*40;
          writefln( "%d players remain playing. Pot contains %d.", finalPlayers, pot);
          // evaluate
          if( otherLoose){
            writefln( "You get the pot containing %d.", pot);
            balance+= pot;
          } else
            if( otherWin)
              writefln( "You loose your odds.");
            else{
              writefln( "The pot gets split. You get %d.", pot/otherSplit);
              balance+= pot/otherSplit;
            }
        } else
          writefln( "You gave up your odds%s", sorry);
      } else
        writefln( "You gave up your odds%s", sorry);
    } else
      writefln( "You gave up your odds%s", sorry);
  } else {
    writefln( "Your bankroll feels lighter%s", sorry);
  }
  ret:
  delete visible;
  delete talon;
  return balance;
}
void main(){
  long balance;
  try{
    do{
      balance+= round();
    }while( true);
  }
  catch(Exception e){ }
  writefln( "Your balance is %d.", balance);
  fwritefln( stderr, "\nThank you for trying PokerBots.");
  fwritefln( stderr, "Hit return to close.");
  din.getc();
  do{
  }while(din.getc() !="\n"[0]);
}
import std.stdio, std.stream, std.cstream;
import talon;
