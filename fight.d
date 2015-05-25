const ulong RUNS= 50_000;
ulong[] rank( int[] list ...){
  ulong[] count;
  count.length= Rank.max+1;
  for( long i= 1; i<=RUNS; i++){
    auto talon= new Talon;
    auto visible= new Visible( talon, list);
    count[ cast(int)visible.analyze()]++;
    delete visible;
    delete talon;
  }
  return count;
}
// bei 1_000_000 1.510188 -0.004210 +0.004282
// fehler 3 promille
real run( int[] list ...){
  real sum=0.0;
  for( long i= 1; i<=RUNS; i++){
    auto talon= new Talon;
    auto visible= new Visible( talon, list);
    sum+= visible.analyze();
    delete visible;
    delete talon;
  }
  return sum/RUNS;
}
void main(){
  const int PLAYERS= 10;
  const int EXACTNESS= 1;
  const int BUCKETS= EXACTNESS*Rank.max;
  const int ODDSpreShowdown= 10+5+10;
  const int ODDSshowdown= 20;
  const real BLIND= 7.0;
  const real RAKE_MAX= 3.0;
  const real ODDS= ODDSpreShowdown+ ODDSshowdown;
  debug {
    const real Pshowdown= 0.7937;
    const real pp= ( 1.0 -Pshowdown) / 17.0;
    const real[] fld= [ 6.0*pp, 5.0*pp, 4.0*pp, 2.0*pp]; 
    const real[4] fold; 
    fold[ 0]= fld[0];
    for( int i= 1; i< 4; i++)
      fold[ i]= fold[ i -1] + fld[i];
    for( int i= 0; i< 4; i++) writef( fold[i], " ");
    writefln();
  }
  bool[ uint]foldTable;
  if( false){
    for( int i= 2+13; i<= 11+13; i++) foldTable[ i*13+1]= true;
    for( int i= 3+13; i<= 11+13; i++) foldTable[ i*13+2]= true;
    for( int i= 5+13; i<= 11+13; i++) foldTable[ i*13+3]= true;
    for( int i= 7+13; i<= 10+13; i++) foldTable[ i*13+4]= true;
    for( int i= 5   ; i<=  8   ; i++) foldTable[ i*13+1]= true;
    for( int i= 7   ; i<=  8   ; i++) foldTable[ i*13+2]= true;
    foldTable[ 2*13+1]= true;
  }
  static int[ 13] accTable= [ 0, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1];
  for( int lowI=0; lowI <13; lowI++){
    auto low= accTable[ lowI];
    for( int higI=lowI; higI <13; higI++){
      auto hig= accTable[ higI];
      const uint LEN= PLAYERS -1 + 1 + 3;
      char[ LEN*3+10][2] lines= ' ';
      uint linesToPrint= 0;
      for( int unsuited= (low==hig); unsuited <= 1; unsuited++){
        auto sec= hig+13*unsuited;
        if( !( sec*13+low in foldTable)){
          real nwin[ PLAYERS+1]=0;
          debug real nwinLate[ PLAYERS+1][BUCKETS]=0;
          real nplay[ PLAYERS+1]=0;
          debug real nplayLate[ PLAYERS+1][BUCKETS]=0;
          for( long i= 1; i<=RUNS; i++){
            auto Talon talon= new Talon;
            Visible[ PLAYERS] cards;
            cards[0]= new Visible( talon, low, sec);
            { // other players see same table
              int[5] table;
              for( int j= 0; j<5; j++)
                table[ j]= cards[0].visible[ j+2];
              for( int j= 1; j <PLAYERS; j++)
                cards[j] =new Visible( talon, cast(creal)1.0, table);
            }
            bool otherLoose= true;
            bool otherWin= false;
            int otherFolds= 0;
            int totalPlayers= 1;
            real playerVal= cards[0].analyze();
            for( int j= 1; j <PLAYERS; j++){
                auto fir= cards[j].visible[5]%13;
                auto sec2= cards[j].visible[6]%13;
                if( cards[j].visible[5]/13 != cards[j].visible[6]/13) sec2+= 13;
              auto thisOneFolds= false && sec2*13+fir in foldTable;
              if( thisOneFolds){
                // nothing to consider
              } else {
                totalPlayers++;
                auto otherVal=cards[j].analyze();
                otherLoose &= playerVal > otherVal;
                otherWin |= playerVal<otherVal;
                { // evaluate
                  nplay[ j]++;
                  real finalPlayers= totalPlayers*1.0;
                  if( finalPlayers < 2.0) finalPlayers= 2.0;
                  real winBeforeRake = ODDS * finalPlayers + BLIND;
                  real rake= winBeforeRake * 0.05;
                  if( rake > 3) rake= 3;
                  version( money)
                    real winAfterRake = winBeforeRake - rake;
                  else
                    real winAfterRake = 1.0;
                  if( otherLoose)
                    {}// no change to winAfterRake
                  else
                    if( otherWin)
                      winAfterRake = 0;
                    else
                      winAfterRake /= 2.0;
                  version(money)
                    nwin[ j] += winAfterRake - ODDS; // blinds not computed!
                  else
                    nwin[ j] += winAfterRake;
                }
                debug{ // latefold
                  auto bucket= cast(long)(EXACTNESS*otherVal);
                  nplayLate[ j][ bucket]++;
                  nwinLate[ j][ bucket]-= ODDSpreShowdown; //TODO 
                }
              }
            }
            delete talon;
          }
          real[ PLAYERS] erg;
          for( int j= 1; j <PLAYERS; j++){
            erg[j]= nwin[ j]/nplay[j];
          }
          debug for( int j= PLAYERS; j >1; j--){
            real w=nwin[j], p=nplay[j];
            for( int val= 1; val < BUCKETS; val++){
              w= nwinLate[j][val];
              p= nplayLate[j][val];
              erg[ val][ j]= w/p;
            }
          }
          bool pr=false;
          version(money)
            byte[ PLAYERS] ergf;
          else
            real[ PLAYERS] ergf;
          const real limitStart= 0.0;
          const real limitRun= 0.0;
          assert( limitStart <= limitRun);
          for( int j= 1; j <PLAYERS; j++){
            auto mx= erg[j];
            auto prl= mx>=limitStart;
            pr|= true | prl;
            version(money){
              auto blinds= cast(int) floor(mx/5);
              if( blinds > 9) blinds= 9;
              if( blinds >= 0) 
                ergf[ j]= '0' + blinds;
              else 
                ergf[ j]= 'a' + ( -1 - blinds);
              debug writefln( mx, " ",
                Visible.sprint(low)[0],
                Visible.sprint(hig)[0],
                " debug"
              );
    thisLoop:
              debug for( int row= 1; row <= BUCKETS; row++){
                auto now= erg[row][j];
                if( now> mx && limitRun > mx){
                  pr= true;
                  mx= now;
                  ergf[j]='0' +row/ EXACTNESS;
                  break thisLoop;
                }
              }
            } else {
              ergf[ j]= mx;
            }
          }
          if( pr){
            linesToPrint++;
            version(money){
              for( int j= 1; j < PLAYERS; j++){
                lines[unsuited][ j-1]= cast(char)ergf[j];
              }
              lines[unsuited][ LEN-4]= ' ';
              lines[unsuited][ LEN-3]= Visible.sprint(low)[0];
              lines[unsuited][ LEN-2]= Visible.sprint(hig)[0];
              lines[unsuited][ LEN-1]= low==hig? ' ' : (sec/13==0?'s':'u');
            } else {
              lines[unsuited][ 0]= Visible.sprint(low)[0];
              lines[unsuited][ 1]= Visible.sprint(hig)[0];
              lines[unsuited][ 2]= low==hig? ' ' : (sec/13==0?'s':'u');
              lines[unsuited][ 3]= ' ';
              for( int j= 1; j < PLAYERS; j++){
                lines[unsuited][ 3*j+1 .. 3*j+3]= toString(100*ergf[j])[0 .. 2].dup;
              }

            }
            debug writefln( lines[unsuited], "debug");
          }
        }
      }
      switch( linesToPrint ){
        case 0: break;
        case 2: if( lines[0][4 .. LEN-1] == lines[1][4 .. LEN-1]){
                  writefln( lines[0][0 .. LEN-1]);
                  break;
                }
        case 1: if( lines[0][0] != ' ')
                  writefln( lines[0]);
                if( lines[1][0] != ' ')
                  writefln( lines[1]);
      }
      debug writefln( lines[unsuited]);
      fwritef( stderr, ".");
    }
  }
}
import std.stdio, std.stream, talon, std.math, std.string;
