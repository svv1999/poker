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
  static const ushort NIL= 52;
  void common(int target, int card){
    set.count--;
    set.set[ target]= set.set[ set.count];
    ptr[ set.set[ target]]= target;
    ptr[ card]= NIL;
  }
}



enum Rank{ HIGH, PAIR, DPAIR, THREE, STREET, FLUSH, FULL, FOUR, SFLUSH, RFLUSH};
class Visible{
  static const uint VISIBLE= 7;
  int[ VISIBLE] visible;
  this( Talon talon, int[] list ...){
    for( int i= 0; i< list.length; i++)
      visible[ i]= talon.draw( list[i]);
    for( int c=list.length; c<VISIBLE; c++)
      visible[ c]= talon.draw;
  }
  this( Talon talon, creal b, int[] list ...){
    for( int i= 0; i< list.length; i++)
      visible[ i]= list[i];
    for( int c=list.length; c<VISIBLE; c++)
      visible[ c]= talon.draw;
  }
  void print(){
    for( int c=0; c<VISIBLE; c++)
      show( c);
    //writefln();
  }
  static char[] sprint( int card){
    debug fwritefln( stderr, "[sprint ");
    char[] retval;
    char[5] color= "CSHDX";
    char[14] kind= "A23456789TJQKX";
    retval.length= 2;
    retval[0]= kind[card % 13];
    retval[1]= color[card/13];
    debug fwritefln( stderr, "] ");
    return retval.dup;
  }
  char[] show( int place){
    debug fwritefln( stderr, "[show ");
    auto retval= sprint( visible[ place]);
    debug fwritefln( stderr, "] ");
    return retval.dup;
  }
  real analyze(){
    struct Detail{
      bool val;
      int data;
      int grade;
    }
    Detail flush(){
      int[ 4] flsh;
      for( int c=0; c<VISIBLE; c++)
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
      if( retval.val){
        retval.grade= 0;
        for( int c=0; c<VISIBLE; c++)
          if( visible[c]/13 == col)
            if( visible[c]%13 > retval.grade)
              retval.grade= visible[c]%13;
            else
              if( visible[c]%13 == 0)
                retval.grade= 13;
        retval.grade--;
      }
      return retval;
    }
    alias bool delegate (int,int) DG;
    DG constant=delegate bool (int i, int col){ return true;};
    DG variable=delegate bool (int i, int col){ return (visible[i]/13==col);};
    Detail street( DG dg, int col){
      Detail retval;
      bool[13] row= false;
      for( int i=0; i<VISIBLE; i++)
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
      Detail retval;
      int[ 13] row;
      for( int i=0; i<VISIBLE; i++)
        row[ visible[ i]%13]++;
      int[ 5] mx;
      //unrolled
      ushort assigned= 0;
      mx[ row[0]]++;
      if( row[0] > 1){
        retval.grade=12;
        assigned++;
      }
      for( int i= 12; i>0; i--){
        mx[ row[i]]++;
        switch( row[i]){
          case 2:
            if( assigned <2 && !mx[4]) retval.grade=retval.grade*100+(i-1);
            assigned++;
            break;
          case 3:
            if( assigned < 1) retval.grade=(i-1);
            assigned++;
            break;
          case 4:
            retval.grade= (i-1);
            assigned++;
            break;
          default:
        }
      }
      retval.data= mx[4]*100+mx[3]*10+mx[2];
      retval.val= retval.data > 0;
      return retval;
    }
    Detail high(){
      int mx= 0;
      for( int i=0; i<VISIBLE; i++)
        if( visible[ i]%13==0)
          mx=12;
        else
          if( visible[ i]%13 > mx)
            mx= visible[i]%13;
      Detail retval;
      retval.grade= mx;
      return retval;
    }
    real comb2( int val){
      real hig= val/100;
      real low= val%100;
      auto retval= (hig*(hig-1)/2 + low)/78.0;
      //writefln("%f %f %f", hig, low, retval);
      assert( retval < 1.0);
      return retval;
    }
    debug writefln( "street: %2d, flush: %2d, kind: %3d", street(), flush(), kind());
    auto col=flush();
    auto st= street( variable, col.data);
    //if( col.val && st.grade==13) return Rank.RFLUSH+1; // 1S0K
    real retval;
    if( col.val && st.grade>0){
      retval= cast(real)Rank.SFLUSH+(st.grade-4.0)/10.0; // 10S0K
      debug writef( "SFLUSH");
      goto ret;
    }
    auto k= kind();
    if( k.val && k.data >= 100){
      retval= cast(real)Rank.FOUR+k.grade/13.0; // 13S1K
      debug{
        writef( "FOUR(%d, ", k.grade);
        for( int i=0; i<VISIBLE; i++) writef( "%x%x ", visible[i]/13, visible[i]%13);
        writef( ")");
      }
      goto ret;
    }
    if( k.val && k.data >= 11){
      retval= cast(real)Rank.FULL+comb2(k.grade); // 81s0k
      debug writef( "FULL");
      goto ret;
    }
    if( col.val && k.val){
      retval= cast(real)Rank.FLUSH+col.grade/8.0; // 8s0k
      debug writef( "FLUSH");
      goto ret;
    }
    st= street( constant, col.data);
    if( st.val){
      retval= cast(real)Rank.STREET+st.grade/10.0; //10s0k
      debug writef( "STREET");
      goto ret;
    }
    if( k.val && k.data >= 10){
      retval= cast(real)Rank.THREE+k.grade/13.0; // 13s2k
      debug writef( "THREE");
      goto ret;
    }
    if( k.val && k.data >= 2){
      retval= cast(real)Rank.DPAIR+comb2(k.grade);  // 81s1k
      debug writef( "DPAIR");
      goto ret;
    }
    if( k.val && k.data >= 1){
      retval= cast(real)Rank.PAIR+k.grade/13.0; // 13s3k
      debug writef( "PAIR");
      goto ret;
    }
    auto h= high();
      retval= cast(real)Rank.HIGH+(h.grade-5.0)/8.0; // 8s4k
      debug writef( "HIGH");

    ret:
    debug writef( "%f ", retval);
    assert( retval < cast(real)Rank.RFLUSH);
    return retval;
  }
}
uint rnd(uint base, uint range) {
  return
    cast(uint)(
      base
      + (1.0*range*rand()) / (uint.max+1.0)
    );
}

import std.random, std.stdio;
