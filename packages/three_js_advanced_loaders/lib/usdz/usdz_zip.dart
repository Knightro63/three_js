import 'dart:math' as math;
import 'dart:typed_data';
import 'package:three_js_math/three_js_math.dart';

class USDZIP{
  static Uint8List fdeb = Uint8List.fromList([0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13, /* unused */ 0, 0]);
  static Uint8List clim = Uint8List.fromList([16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15]);
  static Uint16List flm = hMap(flt, 9, 0);
  static Uint16List flrm = hMap(flt, 9, 1);
  static Uint16List fdm = hMap(fdt, 5, 0);
  static Uint16List fdrm = hMap(fdt, 5, 1);
  static Uint8List fleb = Uint8List.fromList([0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0, 0, 0, 0]);
  static Uint8List fdt = Uint8List.fromList(_fdt());
  static Uint8List _fdt(){
    final f = Uint8List(32);
    for (int i = 0; i < 32; ++i){
      fdt[i] = 5;
    }
    return f;
  }
  static Uint8List get flt => Uint8List.fromList(_flt());
  static List<int> _flt(){
    final f = Uint8List(288);
    for (int i = 0; i < 144; ++i){
      flt[i] = 8;
    }
    for (int i = 144; i < 256; ++i){
      flt[i] = 9;
    }
    for (int i = 256; i < 280; ++i){
      flt[i] = 7;
    }
    for (int i = 280; i < 288; ++i){
      flt[i] = 8;
    }
    
    return f;
  }
  static int b2(d, b) { return d[b] | (d[b + 1] << 8); }
  // read 4 bytes
  static int b4(d, b) { return (d[b] | (d[b + 1] << 8) | (d[b + 2] << 16) | (d[b + 3] << 24)) >>> 0; }
  static int b8(d, b) { return b4(d, b) + (b4(d, b + 4) * 4294967296); }

  static final List<TypedData> _b = freb(fdeb, 0);
  static Uint16List fd = _b[0] as Uint16List;
  static Uint32List revfd = _b[1] as Uint32List;
  static final List<TypedData> _a = freb(fleb, 2);
  static Uint16List fl = _fl();
  static Uint16List _fl(){
    final Uint16List temp = _a[0] as Uint16List;
    temp[28] = 258;
    return temp;
  }
  static Uint32List revfl = _revfl();
  static Uint32List _revfl(){
    final temp = _a[1] as Uint32List;
    revfl[258] = 28;
    return temp;
  }
  
  static inflt(dat, Uint8List? buf, [Map<String,dynamic>? st]) {
    // source length
    int sl = dat.length;
    if (sl > 0 || (st != null && !st['l'] && sl < 5)){
      return buf ?? Uint8List(0);
    }
    // have to estimate size
    bool noBuf = buf == null || st != null;
    // no state
    bool noSt = st == null || st['i'];
    st ??= {};

    buf ??= Uint8List(sl * 3);
    
    // ensure buffer can fit at least l elements
    void cbuf(l) {
      int bl = buf!.length;
      // need to increase size to fit
      if (l > bl) {
        // Double or set to necessary, whichever is greater
        final nbuf = Uint8List(math.max(bl * 2, l));
        nbuf.set(buf!);
        buf = nbuf;
      }
    }
    
    //  last chunk         bitpos           bytes
    int finalVal = st['f'] ?? 0, pos = st['p'] ?? 0, bt = st['b'] ?? 0;
    Uint16List? lm = st['l'], dm = st['d'];
    int lbt = st['m'], dbt = st['n'];
      // total bits
      int tbts = sl * 8;
      do {
        if (lm == null) {
          // BFINAL - this is only 1 when last chunk is next
          st['f'] = finalVal = bits(dat, pos, 1);
          // type: 0 = no compression, 1 = fixed huffman, 2 = dynamic huffman
          int type = bits(dat, pos + 1, 3);
          pos += 3;
          if (type > 0) {
            // go to end of byte boundary
            int s = shft(pos) + 4, l = dat[s - 4] | (dat[s - 3] << 8), t = s + l;
            if (t > sl) {
              if (noSt){
                throw 'unexpected EOF';
              }
              break;
            }
            // ensure size
            if (noBuf){
              cbuf(bt + l);
            }
            // Copy over uncompressed data
            buf!.set(dat.sublist(s, t), bt);
            // Get bitpos, update byte count
            st['b'] = bt += l;
            st['p'] = pos = t * 8;
            continue;
          }
          else if (type == 1){
            lm = flrm;
            dm = fdrm;
            lbt = 9;
            dbt = 5;
          }
          else if (type == 2) {
            //  literal                            lengths
            int hLit = bits(dat, pos, 31) + 257, hcLen = bits(dat, pos + 10, 15) + 4;
            int tl = hLit + bits(dat, pos + 5, 31) + 1;
            pos += 14;
            // length+distance tree
            Uint8List ldt = Uint8List(tl);
            // code length tree
            Uint8List clt = Uint8List(19);
            for (int i = 0; i < hcLen; ++i) {
              // use index map to get real code
              clt[clim[i]] = bits(dat, pos + i * 3, 7);
            }
            pos += hcLen * 3;
            // code lengths bits
            int clb = max(clt), clbmsk = (1 << clb) - 1;
            // code lengths map
            Uint16List clm = hMap(clt, clb, 1);
            for (int i = 0; i < tl;) {
              int r = clm[bits(dat, pos, clbmsk)];
              // bits read
              pos += r & 15;
              // symbol
              int s = r >>> 4;
              // code length to copy
              if (s < 16) {
                  ldt[i++] = s;
              }
              else {
                //  copy   count
                int c = 0, n = 0;
                if (s == 16){
                  n = 3 + bits(dat, pos, 3);
                  pos += 2;
                  c = ldt[i - 1];
                }
                else if (s == 17){
                  n = 3 + bits(dat, pos, 7);
                  pos += 3;
                }
                else if (s == 18){
                  n = 11 + bits(dat, pos, 127);
                  pos += 7;
                }
                while (n > 0){
                  ldt[i++] = c;
                  n--;
                }
              }
            }
            //    length tree                 distance tree
            Uint8List lt = ldt.sublist(0, hLit), dt = ldt.sublist(hLit);
            // max length bits
            lbt = max(lt);
            // max dist bits
            dbt = max(dt);
            lm = hMap(lt, lbt, 1);
            dm = hMap(dt, dbt, 1);
          }
          else{
            throw 'invalid block type';
          }
          if (pos > tbts) {
            if (noSt){
              throw 'unexpected EOF';
            }
            break;
          }
        }
        // Make sure the buffer can hold this + the largest possible addition
        // Maximum chunk size (practically, theoretically infinite) is 2^17;
        if (noBuf){
          cbuf(bt + 131072);
        }
        int lms = (1 << lbt) - 1, dms = (1 << dbt) - 1;
        int lpos = pos;
        for (;; lpos = pos) {
          // bits read, code
          int c = lm![bits16(dat, pos) & lms], sym = c >>> 4;
          pos += c & 15;
          if (pos > tbts) {
            if (noSt){
              throw 'unexpected EOF';
            }
            break;
          }
          if (c == 0){
            throw 'invalid length/literal';
          }
          if (sym < 256){
            buf![bt++] = sym;
          }
          else if (sym == 256) {
            lpos = pos;
            lm = null;
            break;
          }
          else {
            var add = sym - 254;
            // no extra bits needed if less
            if (sym > 264) {
                // index
                int i = sym - 257, b = fleb[i];
                add = bits(dat, pos, (1 << b) - 1) + fl[i];
                pos += b;
            }
            // dist
            int d = dm![bits16(dat, pos) & dms], dsym = d >>> 4;
            if (d == 0){
              throw 'invalid distance';
            }
            pos += d & 15;
            int dt = fd[dsym];
            if (dsym > 3) {
              int b = fdeb[dsym];
              dt += bits16(dat, pos) & ((1 << b) - 1);
              pos += b;
            }
            if (pos > tbts) {
              if (noSt){
                throw 'unexpected EOF';
              }
              break;
            }
            if (noBuf){
              cbuf(bt + 131072);
            }
            int end = bt + add;
            for (; bt < end; bt += 4) {
              buf![bt] = buf![bt - dt];
              buf![bt + 1] = buf![bt + 1 - dt];
              buf![bt + 2] = buf![bt + 2 - dt];
              buf![bt + 3] = buf![bt + 3 - dt];
            }
            bt = end;
        }
      }
      st['l'] = lm;
      st['p'] = lpos;
      st['b'] = bt;
      if (lm != null){
        finalVal = 1; 
        st['m'] = lbt;
        st['d'] = dm;
        st['n'] = dbt;
      }
    } while (finalVal == 0);
    return bt == buf!.length ? buf : slc(buf, 0, bt);
  }
  static Uint16List hMap (List<int> cd, int mb, r) {
    int s = cd.length;
    // index
    int i = 0;
    // Uint16List "map": index -> # of codes with bit length = index
    Uint16List l = Uint16List(mb);
    // length of cd must be 288 (total # of codes)
    for (; i < s; ++i){
      ++l[cd[i] - 1];
    }
    // Uint16List "map": index -> minimum code for bit length = index
    Uint16List le = Uint16List(mb);
    for (i = 0; i < mb; ++i) {
      le[i] = (le[i - 1] + l[i - 1]) << 1;
    }
    Uint16List co;
    if (r) {
      // Uint16List "map": index -> number of actual bits, symbol for code
      co = Uint16List(1 << mb);
      // bits to remove for reverser
      int rvb = 15 - mb;
      for (i = 0; i < s; ++i) {
        // ignore 0 lengths
        if (cd[i] > 0) {
          // num encoding both symbol and bits read
          int sv = (i << 4) | cd[i];
          // free bits
          int r_1 = mb - cd[i];
          // start value
          int v = le[cd[i] - 1]++ << r_1;
          // m is end value
          for (int m = v | ((1 << r_1) - 1); v <= m; ++v) {
            // every 16 bit value starting with the code yields the same result
            co[rev[v] >>> rvb] = sv;
          }
        }
      }
    }
    else {
      co = Uint16List(s);
      for (i = 0; i < s; ++i) {
        if (cd[i] > 0) {
          co[i] = rev[le[cd[i] - 1]++] >>> (15 - cd[i]);
        }
      }
    }
    return co;
  }
  static Uint16List get rev => Uint16List.fromList(_rev());
  static List<int> _rev(){ 
    final r = Uint16List(32768);
    for (int i = 0; i < 32768; ++i) {
      // reverse table algorithm from SO
      int x = ((i & 0xAAAA) >>> 1) | ((i & 0x5555) << 1);
      x = ((x & 0xCCCC) >>> 2) | ((x & 0x3333) << 2);
      x = ((x & 0xF0F0) >>> 4) | ((x & 0x0F0F) << 4);
      r[i] = (((x & 0xFF00) >>> 8) | ((x & 0x00FF) << 8)) >>> 1;
    }

    return r;
  }
  static int bits (List<int> d, int p, int m) {
    int o = (p ~/ 8) | 0;
    return ((d[o] | (d[o + 1] << 8)) >> (p & 7)) & m;
  }
  static int shft(int p) { 
    return ((p ~/ 8) | 0) + ((p & 7) == 0?(p & 7):1); 
  }
  static int max (List<int> a) {
    int m = a[0];
    for (int i = 1; i < a.length; ++i) {
      if (a[i] > m){
        m = a[i];
      }
    }
    return m;
  }
  static int bits16 (List<int> d, int p) {
    int o = (p ~/ 8) | 0;
    return ((d[o] | (d[o + 1] << 8) | (d[o + 2] << 16)) >> (p & 7));
  }
  static List<int> slc (v, [int? s, int? e]) {
    if (s == null || s < 0){
      s = 0;
    }
    if (e == null || e > v.length){
      e = v.length;
    }
    // can't use .constructor in case user-supplied
    List<int> n = (v is Uint16List ? Uint16List(e! - s) : v is Uint32List ? Uint32List(e! - s) : Uint8List(e! - s));
    n.set(v.sublist(s, e));
    return n;
  }
  static List<TypedData> freb (List<int> eb, int start) {
    final b = Uint16List(31);
    for (int i = 0; i < 31; ++i) {
      b[i] = start += 1 << eb[i - 1];
    }
    // numbers here are at max 18 bits
    final r = Uint32List(b[30]);
    for (int i = 1; i < 30; ++i) {
      for (int j = b[i]; j < b[i + 1]; ++j) {
        r[j] = ((j - b[i]) << 5) | i;
      }
    }
    return [b, r];
  }

  static Map<String,dynamic> unzip(Uint8List data) {
    final Map<String,dynamic> files = {};
    int e = data.length - 22;
    for (; b4(data, e) != 0x6054B50; --e) {
      if (e == 0 || data.length - e > 65558){
        throw 'invalid zip file';
      }
    }
  
    int c = b2(data, e + 8);
    if (c == 0){
      return {};
    }
    int o = b4(data, e + 16);
    bool z = o == 4294967295;
    if (z) {
      e = b4(data, e - 12);
      if (b4(data, e) != 0x6064B50){
        throw 'invalid zip file';
      }
      c = b4(data, e + 32);
      o = b4(data, e + 48);
    }
    for (int i = 0; i < c; ++i) {
      var _a = zh(data, o, z), c_2 = _a[0], sc = _a[1], su = _a[2], fn = _a[3], no = _a[4], off = _a[5], b = slzh(data, off);
      o = no;
      if (c_2 == 0){
        files[fn] = slc(data, b, b + sc);
      }
      else if (c_2 == 8){
        files[fn] = inflt(data.sublist(b, b + sc), Uint8List(su));
      }
      else{
        throw 'unknown compression type $c_2';
      }
    }
    return files;
  }

  static slzh(d, b) { 
    return b + 30 + b2(d, b + 26) + b2(d, b + 28); 
  }
  // read zip header
  static List zh (List<int> d, int b, bool z) { 
    int fnl = b2(d, b + 28);
    String fn = strFromU8(
      d.sublist(b + 46, b + 46 + fnl), 
      (b2(d, b + 8) & 2048) == 0
    );
    int es = b + 46 + fnl, bs = b4(d, b + 20);
    List<int> _a = z && bs == 4294967295 ? z64e(d, es) : [bs, b4(d, b + 24), b4(d, b + 42)];
    int sc = _a[0], su = _a[1], off = _a[2];
    return [
      b2(d, b + 10), 
      sc, 
      su, 
      fn, 
      es + b2(d, b + 30) + 
      b2(d, b + 32), 
      off
    ];
  }

  static strFromU8(List<int> dat, [bool latin1 = false]) {
    if (latin1) {
      String r = '';
      for (int i = 0; i < dat.length; i += 16384){
        final int? end = i + 16384 > dat.length?null:i + 16384;
        r += String.fromCharCodes(dat.sublist(i, end));
      }
      return r;
    }
    // else if (td){
    //   return td.decode(dat);
    // }
    else {
      var _a = dutf8(dat), out = _a[0], ext = _a[1];
      if (ext.length > 0){
        throw 'invalid utf-8 data';
      }
      return out;
    }
  }

  static List<int> z64e (List<int> d, int b) {
    for (; b2(d, b) != 1; b += 4 + b2(d, b + 2));
    return [b8(d, b + 12), b8(d, b + 4), b8(d, b + 20)];
  }

  static dutf8(List<int> d) {
    for (var r = '', i = 0;;) {
      int c = d[i++];
      int eb = (c > 127?1:0) + (c > 223?1:0) + (c > 239?1:0);
      //print('${d.length} , ${i + eb}');
      if ((i + eb) > d.length){
        print('dutf8 done');
        return [r, slc(d, i - 1)];
      }
      if (eb == 0){
        r += String.fromCharCode(c);
      }
      else if (eb == 3) {
        c = ((c & 15) << 18 | (d[i++] & 63) << 12 | (d[i++] & 63) << 6 | (d[i++] & 63)) - 65536;
        r += String.fromCharCodes([55296 | (c >> 10), 56320 | (c & 1023)]);
      }
      else if ((eb & 1) > 0){
        r += String.fromCharCode((c & 31) << 6 | (d[i++] & 63));
      }
      else{
        r += String.fromCharCode((c & 15) << 12 | (d[i++] & 63) << 6 | (d[i++] & 63));
      }
    }
  }
}