/** for the pocket cards there is n=52*51=2652
  these can be partioned into
  suited: ns=13(first)* 12(second) * 4(colors)
  unsuited: nu=13(first)* 13(second) * 3(color of second) *4(color of first)
  total: 2652=n=ns+nu=13*12*4+13*13*3*4= 624+2028= 2652
*/

class Talon{
  this(){
    set.count= 52;
    for( int c=0; c<52; c++){
      set.set[ c]= c;
      ptr[ c]= c;
    }
  }
  int draw(){ /// draw a random member
    auto target= rnd( 0, set.count);
    auto card= set.set[ target];
    common( target, card);
    return card;
  }
  int draw(int card){ ///draw a specific member
    assert( ptr[ card] != NIL);
    auto target= ptr[ card];
    common( target, card);
    return card;
  }
  private:
  struct Set{
    int[ 52] set=void;
    ushort count=void;
  } Set set; 
  int[ 52] ptr=void;
  const ushort NIL= 52;
  void common(int target, int card){
    set.count--;
    set.set[ target]= set.set[ set.count];
    ptr[ set.set[ target]]= target;
    ptr[ card]= NIL;
  }
}
  enum Comb{ HIGH, PAIR, DPAIR, THREE, STREET, FLUSH, FULL, FOUR, SFLUSH, RFLUSH};
class Visible{
  int[ 7] visible;
  this( Talon talon, int[] list ...){
    for( int i= 0; i< list.length; i++)
      visible[ i]= talon.draw( list[i]);
    for( int c=list.length; c<7; c++)
      visible[ c]= talon.draw;
  }
  void print(){
    for( int c=0; c<7; c++)
      writef( "%x%x ", visible[c]/13, visible[c] % 13);
    //writefln();
  }
  Comb analyze(){
    struct Detail{
      bool val;
      int data;
      int grade;
    }
    Detail flush(){
      int[ 4] flsh;
      for( int c=0; c<7; c++)
	flsh[ visible[c]/13]++;
      int mx= 0;
      int col= 0;
      for( int s=0; s<4; s++)
	if( flsh[ s]> mx){
	  mx= flsh[s];
	  col= s;
	}
      Detail retval;
      retval.val= mx>= 5;
      retval.data= col;
      return retval;
    }
    alias bool delegate (int,int) DG;
    DG constant=delegate bool (int i, int col){ return true;};
    DG variable=delegate bool (int i, int col){ return (visible[i]/13==col);};
    Detail street( DG dg, int col){
      Detail retval;
      bool[13] row= false;
      for( int i=0; i<7; i++)
	row[ visible[ i]%13]= dg( i, col);
      int start;
      if( row[0]) start= 13;
      for( int i=12; i>=0; i--){
	if( row[ i]){
	  if( i+4 == start){
	    retval.val= true;
	    retval.grade= start;
	    return retval;
	  }
	  if( start==0)
	    start= i; 
	} else
	  start= 0;
	debug if( dopr)writefln( "%d %d %d", i, row[i], start);
      }
      retval.val= false;
      return retval;  
    }
    Detail kind(){
      int[ 13] row;
      for( int i=0; i<7; i++)
	row[ visible[ i]%13]++;
      int[ 5] mx;
      for( int i= 0; i<13; i++)
	mx[ row[i]]++;
      Detail retval;
      retval.data= mx[4]*100+mx[3]*10+mx[2];
      retval.val= retval.data > 0;
      return retval;
    }
    debug writefln( "street: %2d, flush: %2d, kind: %3d", street(), flush(), kind());
    auto col=flush();
    auto st= street( variable, col.data);
    if( col.val && st.grade==13) return Comb.RFLUSH;
    if( col.val && st.grade>0) return Comb.SFLUSH;
    auto k= kind();
    if( k.val && k.data >= 100) return Comb.FOUR;
    if( k.val && k.data >= 11) return Comb.FULL;
    if( k.val && col.val) return Comb.FLUSH;
    if( street( constant, col.data).val) return Comb.STREET;
    //if( street()) return Comb.STREET;
    if( k.val && k.data >= 10) return Comb.THREE;
    if( k.val && k.data >= 2) return Comb.DPAIR;
    if( k.val && k.data >= 1) return Comb.PAIR;
    return Comb.HIGH;
  }
}
const ulong RUNS= 6_000;
real run( int[] list ...){
  ulong[ Comb.max+1] count= 0;
  for( long i= 1; i<=RUNS; i++){
    auto talon= new Talon;
    auto visible= new Visible( talon, list);
    count[ visible.analyze()]++;
    delete visible;
    delete talon;
  }
  real sum=0.0;
  for( int i= 1; i<= Comb.max; i++)
    sum+= i*( cast(real)count[i]/RUNS);
  return sum;
}
void main(){
  real[ 20] stage;
  // stage 0
  real sum= 0.0;
  for( int i=0; i < RUNS; i++)
    sum+= run();
  stage[ 0]= sum/ RUNS;
  //stage 1
  for( int low=0; low <13; low++){
    for( int hig=low+1; hig <26; hig++){
      auto erg=100.0*(run( low, hig)/stage[0]-1.0);
      if( erg> 0.0)writefln( "%x%x%s -> %f", low, hig%13,  hig/13==0?"s":"u", erg);
    }
  }
}
unittest{
  //stage 2
  const ulong runs= 6_000;
  for( int low=0; low <13; low++){
    for( int hig=low+1; hig <26; hig+= (hig<13?1:(hig==13?(low==0?1:low):1))){
      ulong[ Comb.max+1] count= 0;
      for( long i= 1; i<=runs; i++){
	auto talon= new Staple;
	auto visible= new Visible( talon, hig, low);
	count[ visible.analyze()]++;
	delete visible;
	delete talon;
      }
      real sum=0.0;
      for( int i= 1; i<= Comb.max; i++)
	sum+= i*( cast(real)count[i]/runs);
      auto erg=100.0*sum/1.557707-100.0;
      if( erg> 0.0)writefln( "%x%x%s -> %f", hig%13, low, hig/13==0?"s":"u", erg);
    }
  }
}
unittest{
  //stage 3
  const ulong runs= 60_000;
  struct Vals{
    int low, hig;
    real res;
  }
  Vals[] combs;
  combs.length= 101;
  int inx=0;
  // the suited weight=4 -> n=78*2*4=624
  for( int i=0; i<12; i++)
    for( int j=i+1; j<13; j++){
	  combs[ inx].low= i;
	  combs[inx].hig=j;
	  inx++;
    }
  // the pairs weight=12 -> n=13*12=156
  for( int i=0; i<13; i++){
    combs[ inx].low= i;
    combs[inx].hig=i+13;
    inx++;
  }
  // the seqs weight=24 ->n=168
  for( int i=4; i<11; i++){
    combs[ inx].low= i-1;
    combs[ inx].hig= i;
    inx++;
  }
  // the jumps weight=24 -> n=72 -> 1020/2652
  for( int i=4; i<7; i++){
    combs[ inx].low= i-2;
    combs[ inx].hig= i;
    inx++;
  }
  writefln( inx);
  assert( inx==78+13+7+3);

  for( int r= 0; r< 101; r++){
      auto hig= combs[ r].hig;
      auto low= combs[ r].low;
      debug writefln( "%d %d", hig, low);
      ulong[ Comb.max+1] count= 0;
      for( long i= 1; i<=runs; i++){
	auto talon= new Talon;
	auto visible= new Visible( talon, hig, low);
	debug if( visible.analyze()==Comb.STREET){
	  visible.print();
	  writefln();
	  visible.dopr=true;
	  visible.analyze();
	  visible.dopr=false;
	}
	count[ visible.analyze()]++;
	delete visible;
	if( i%1_000_000 == 0){
	  for( int j=0; j< 3; j++)
	    writef( "%7.4f ", 100.0*count[ j]/i);
	  for( int j=3; j< Comb.max+1; j++)
	    writef( "%6.4f ", 100.0*count[ j]/i);
	  writefln();
	}
      }
      real sum=0.0;
      for( int i= 1; i<= Comb.max; i++)
	sum+= i*( cast(real)count[i]/runs);
      combs[ r].res= sum;
      writefln( "%x%x%s -> %f", hig%13, low, hig/13==0?"s":"u", sum);
  }
  real sum= 0.0;
  for( int i= 0; i< 78; i++)
    sum+= 8* combs[i].res;
  for( int i= 78; i< 91; i++)
    sum+= 12* combs[i].res;
  for( int i= 92; i< 101; i++)
    sum+= 24* combs[i].res;
  writefln( "total -> %f", sum/1020);///1.735383 
}
unittest{
  //stage 4
  const ulong runs= 12_000;

  for( int r1= 0; r1< 13-1; r1++){
   for( int r2= r1+1; r2< 13; r2++){
    for( int r3= 13; r3< 26; r3++){
    for( int r4= r3+13; r4< 39; r4++){
    for( int r5= r4+13; r5< 52; r5++){
      ulong[ Comb.max+1] count= 0;
      for( long i= 1; i<=runs; i++){
	auto talon= new Talon;
	auto visible= new Visible( talon, r1, r2, r3, r4, r5);
	count[ visible.analyze()]++;
	delete visible;
	if( i%1_000_000 == 0){ // show spinning
	  for( int j=0; j< 3; j++)
	    writef( "%7.4f ", 100.0*count[ j]/i);
	  for( int j=3; j< Comb.max+1; j++)
	    writef( "%6.4f ", 100.0*count[ j]/i);
	  writefln();
	}
      }
      real sum=0.0;
      for( int i= 1; i<= Comb.max; i++)
	sum+= i*( cast(real)count[i]/runs);
      auto erg=100.0*sum/1.735383-100.0;
      //if( erg>0.0)writefln( "%x%x%x%x%x -> %f", r1%13, r2%13, r3%13,r4%13, r5%13 erg);
      if( erg>0.0){
	//writef( "%x%x%x%x%x ", r1%13, r2%13, r3%13);
	writefln( "%x%x%x%x%x", r1%13, r2%13, r3%13, r4%13, r5%13);
      };// else fwritef(stderr,".");
    }
    }
    }
   }
  }
}
unittest{
  int conv( char c){
    int retval;
    if( c <= '9') retval= c - '0';
    else retval= 10 +c - 'a';
    debug writef( "%d->%d ", c,retval);
    return retval;
  }
  // read  flops
  auto f=new File( "data");
  while( !f.eof){
      byte[5] seq;
      for( int i=0; i<5; i++)
        f.read( seq[i]);
      f.readLine();

      auto r1= conv( seq[0]);
      auto r2= conv( seq[1]);
      auto r3= conv( seq[2])+13;
      auto r4= conv( seq[3])+26;
      auto r5= conv( seq[4])+39;
      {
	auto talon= new Talon;
	auto visible= new Visible( talon, r1, r2, r3, r4, r5);
	switch( visible.analyze()){
	  //case Comb.HIGH, Comb.PAIR:
	  case Comb.HIGH:
	    writefln( "%x%x%x%x%x", r1%13, r2%13, r3%13, r4%13, r5%13);
	  default:
	}
	delete visible;
      }
  }
}

unittest{
  //stage 7
  const ulong runs= 20;
  // 10->19 100-> 97, 150 -> 137
  //2.66794
  real total=0.0;
  real countl=0.0;

  for( int r1= 0; r1< 13; r1++){
   for( int r2= r1+13; r2< 26; r2+=13){
    bool[ int] set;
    set[ r1]= true;
    set[ r2]= true;
    for( int r3= 0; r3< 39; r3++){
      fwritef( stderr, "%d ", r3);
      if( !(r3 in set)){
    for( int r4= r3+1; r4< 51; r4++){
      if( !(r4 in set)){
    for( int r5= r4+1; r5< 52; r5++){
      if( !(r5 in set)){
      real countll=0.0;
      ulong[ Comb.max+1] count= 0;
      set[ r3]= true;
      set[ r4]= true;
      set[ r5]= true;
    for( int r6= 0; r6< 51; r6++){
      if( !(r6 in set)){
    for( int r7= r6+1; r7< 52; r7++){
      if( !(r7 in set)){
      countll++;
      for( long i= 1; i<=runs; i++){
	auto talon= new Talon;
	auto visible= new Visible( talon, r1, r2, r3, r4, r5);
	count[ visible.analyze()]++;
	delete visible;
      }
      }
    }
    if( countll){
      real sum=0.0;
      for( int i= 1; i<= Comb.max; i++)
	sum+= i*( cast(real)count[i]/countll/runs);
      auto erg=sum;
      total+= erg;
      countl++;
      version( mean)
        writefln( "%x%x%x%x%x -> %f", r1%13, r2%13, r3%13,r4%13, r5%13, erg, total);
      else
      if( erg> 2.445295){
        writefln( "%x%x%x%x%x -> %f", r1%13, r2%13, r3%13,r4%13, r5%13, erg);
      };// else fwritef(stderr,".");
    }
    }
    }
    }
    }
    }
    }
    }
    }
   }
  }
  writefln( "%f", total/countl);
}
uint rnd(uint base, uint range) {
  return
    cast(uint)(
      base
      + (1.0*range*rand()) / (uint.max+1.0)
    );
}
import std.stdio, std.random, std.stream;
