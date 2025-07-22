import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:convert'; 

// aliases for shorter compressed code (most minifers don't do this)
typedef u8 = Uint8List;
typedef u16 = Uint16List;
typedef i32 = Int32List;

class USDZip{
  USDZip();

  Uint8List fleb = u8.fromList([0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0, 0, 0, 0]);
  // fixed distance extra bits
  Uint8List fdeb = u8.fromList([0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13, 0, 0]);
  Int32List deo = i32.fromList([65540, 131080, 131088, 131104, 262176, 1048704, 1048832, 2114560, 2117632]);
  Uint8List clim = u8.fromList([16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15]);
  late final _a = freb(fleb, 2), fl = _a['b']..[28] = 258, revfl = _a['r']..[258] = 28;
  late final _b = freb(fdeb, 0), fd = _b['b'], revfd = _b['r'];

  final et = u8(0);
  final flt = u8.fromList(List.filled(144, 8)+List.filled(256-144, 9)+List.filled(280-256, 7)+List.filled(288-280, 8));
  final fdt = u8.fromList(List.filled(32, 5));
  late final flm = hMap(flt, 9, 0);
  late final fdm = hMap(fdt, 5, 0);

  final rev = u16.fromList(List.generate(32768, (int i){
    int x = ((i & 0xAAAA) >> 1) | ((i & 0x5555) << 1);
    x = ((x & 0xCCCC) >> 2) | ((x & 0x3333) << 2);
    x = ((x & 0xF0F0) >> 4) | ((x & 0x0F0F) << 4);
    return (((x & 0xFF00) >> 8) | ((x & 0x00FF) << 8)) >> 1;
  }));

  Uint8List zip(Map<String,dynamic> data, [Map<String,dynamic>? opts]) {
    opts ??= {};
    final Map<String,dynamic> r = {};
    List files = [];
    fltn(data, '', r, opts);
    int o = 0;
    int tot = 0;
    for (final fn in r.keys) {
      var _a = r[fn], file = _a[0];
      Map<String,dynamic> p = _a[1];
      int compression = (p['level'] ?? 0) == 0 ? 0 : 8;
      u8 f = strToU8(fn); 
      int s = f.length;
      var com = p['comment'] ?? 0;
      var m = (com != 0 && strToU8(com) != 0) ? strToU8(com) : com;//com && strToU8(com);
      int ms = (m != 0 && m.length != 0) ? m.length : m;//m && m.length;
      int exl = exfl(p['extra']);
      if (s > 65535){
        err(11);
      }
      var d = compression != 0? deflateSync(file, p) : file;
      int l = d.length;
      Map<String,Function> c = crc();
      c['p']?.call(file);
      files.add(mrg(p, {
        'size': file.length,
        'crc': c['d']?.call(),
        'c': d,
        'f': f,
        'm': m,
        'u': s != fn.length || (m != 0 && (com.length != ms)),
        'o': o,
        'compression': compression
      }));
      o += 30 + s + exl + l;
      tot += 76 + 2 * (s + exl) + ms + l;
    }
    Uint8List out = u8(tot + 22);
    int oe = o, cdl = tot - o;
    for (int i = 0; i < files.length; ++i) {
      Map f = files[i];
      wzh(out, f['o'], f, f['f'], f['u'], f['c'].length);
      int badd = 30 + (f['f'].length as int) + exfl(f['extra']);
      out.setAll(f['o'] + badd,f['c']);//out[f['c']] = f['o'] + badd;
      wzh(out, o, f, f['f'], f['u'], f['c'].length, f['o'], 
      f['m']);
      o += 16 + badd + (f['m'] is int? (f['m'] as int):(f['m'].length) as int);//(f['m'] != null? f['m'].length : 0) as int;
    }
    wzf(out, o, files.length, cdl, oe);
    return out;
  }

  fltn (dynamic d, String p, Map<String,dynamic> t, Map<String,dynamic> o) {
    final List keys = d is Map?d.keys.toList():(d as List<int>).toList();
    for (final k in keys) {
      var val = d[k];
      String n = p + k.toString();
      Map<String, dynamic> op = o;
      if (val is List && val is! Uint8List){
        op = mrg(o, val[1]);
        val = val[0];
      }
      if (val is List<int>){
        t[n] = [val, op];
      }
      else {
        t[n += '/'] = [u8(0), op];
        fltn(val, n, t, o);
      }
    }
  }

  Uint8List strToU8(String str, [bool latin1 = false]) {
    if (latin1) {
      u8 ar_1 = u8(str.length);
      for (int i = 0; i < str.length; ++i){
        ar_1[i] = str.codeUnitAt(i);
      }
      return ar_1;
    }
    //if (true){
      return utf8.encode(str);//te.encode(str);
    //}

    // var l = str.length;
    // var ar = u8(str.length + (str.length >> 1));
    // var ai = 0;
    // var w = (v) { ar[ai++] = v; };
    // for (var i = 0; i < l; ++i) {
    //   if (ai + 5 > ar.length) {
    //     var n = u8(ai + 8 + ((l - i) << 1));
    //     n.setAll(0,ar);
    //     ar = n;
    //   }
    //   var c = str.codeUnitAt(i);
    //   if (c < 128 || latin1){
    //     w(c);
    //   }
    //   else if (c < 2048){
    //     w(192 | (c >> 6));
    //     w(128 | (c & 63));
    //   }
    //   else if (c > 55295 && c < 57344){
    //     c = 65536 + (c & 1023 << 10) | (str.codeUnitAt(++i) & 1023);
    //     w(240 | (c >> 18));
    //     w(128 | ((c >> 12) & 63));
    //     w(128 | ((c >> 6) & 63));
    //     w(128 | (c & 63));
    //   }
    //   else{
    //     w(224 | (c >> 12));
    //     w(128 | ((c >> 6) & 63));
    //     w(128 | (c & 63));
    //   }
    // }
    // return slc(ar, 0, ai);
  }

  int exfl(Map? ex) {
    int le = 0;
    if (ex != null) {
      for (final k in ex.keys) {
        int l = ex[k].length;
        if (l > 65535){
          err(9);
        }
        le += l + 4;
      }
    }
    return le;
  }

  final List<String> ec = [
    'unexpected EOF',
    'invalid block type',
    'invalid length/literal',
    'invalid distance',
    'stream finished',
    'no stream handler',
    'no callback',
    'invalid UTF-8 data',
    'extra field too long',
    'date not in range 1980-2099',
    'filename too long',
    'stream finishing',
    'invalid zip data'
    // determined by unknown compression method
  ];

  void err(int ind, [String? msg, nt]) {
    throw(msg ?? ec[ind]);
    // e.code = ind;
    // if (Error.captureStackTrace)
    //     Error.captureStackTrace(e, err);
    // if(!nt)
    //   throw e;
    // return e;
  }

  deflateSync(data, Map? opts) {
    return dopt(data, opts ?? {}, 0, 0);
  }

  Map<String,Function> crc() {
    int c = -1;
    return {
      'p': (d) {
        // closures have awful performance
        int cr = c;
        for (int i = 0; i < d.length; ++i){
          cr = crct[(cr & 255) ^ d[i]] ^ (cr >>> 8);
        }
        c = cr;
      },
      'd': () { return ~c; }
    };
  }

  Map<String,dynamic> mrg( a, b) {
    final List keys1 = a is Map?a.keys.toList():(a as List<int>).toList();
    final Map<String,dynamic> o = {};
    for (final k in keys1){
      o[k] = a[k];
    }
    final List keys2 = b is Map?b.keys.toList():(b as List<int>).toList();
    for (final k in keys2){
      o[k] = b[k];
    }
    return o;
  }

  wzh(List<int> d, int b, Map f, List<int> fn, bool u, int c, [int? ce, dynamic co]) {
    int col = co is List? co.length: (co ?? 0);
    int fl = fn.length;
    Map? ex = f['extra'];
    //int col = co.length;//(co != 0 && co?.length != 0) ? (co?.length ?? 0) : co;//co && co.length;
    int exl = exfl(ex);
    wbytes(d, b, ce != null ? 0x2014B50 : 0x4034B50);
    b += 4;
    if (ce != null){
      d[b++] = 20;
      d[b++] = f['os'] ?? 0;
    }
    d[b] = 20;
    b += 2;
    d[b++] = ((f['flag'] ?? 0) << 1) | (c < 0 ? 8 : 0);//(c < 0 && 8);
    d[b++] = u == false? 8 : 0;//u && 8;
    d[b++] = f['compression'] & 255;
    d[b++] = f['compression'] >> 8;
    DateTime dt = DateTime.fromMillisecondsSinceEpoch(f['mtime'] == null ? DateTime.now().millisecondsSinceEpoch : f['mtime']);
    int y = dt.year - 1980;
    if (y < 0 || y > 119){
      err(10);
    }
    wbytes(d, b, (y << 25) | ((dt.month + 1) << 21) | (dt.day << 16) | (dt.hour << 11) | (dt.minute << 5) | (dt.second >> 1));
    b += 4;
    if (c != -1) {
      wbytes(d, b, f['crc']);
      wbytes(d, b + 4, c < 0 ? -c - 2 : c);
      wbytes(d, b + 8, f['size']);
    }
    wbytes(d, b + 12, fl);
    wbytes(d, b + 14, exl);
    b += 16;
    if (ce != null) {
      wbytes(d, b, col);
      wbytes(d, b + 6, f['attrs'] ?? 0);
      wbytes(d, b + 10, ce);
      b += 14;
    }
    d.setAll(b, fn);
    b += fl;
    if (exl != 0) {
      for (final k in ex?.keys ?? []) {
        var exf = ex?[k];
        int l = exf?.length ?? 0;
        wbytes(d, b, k);
        wbytes(d, b + 2, l);
        d.setAll(b+4,exf);
        b += 4 + l;
      }
    }
    if (col != 0){
      d.setAll(b, co);
      b += col;
    }
    return b;
  }
  // write zip footer (end of central directory)
  void wzf(List<int> o, int b, int c, int d, int e) {
    wbytes(o, b, 0x6054B50); // skip disk
    wbytes(o, b + 8, c);
    wbytes(o, b + 10, c);
    wbytes(o, b + 12, d);
    wbytes(o, b + 16, e);
  }
  void wbytes(List<int> d, int b, int v) {
    for (; v > 0; ++b){
      d[b] = v;
      v >>>= 8;
    }
  }

  slc(List<int> v, int? s, int? e) {
    if (s == null || s < 0){
      s = 0;
    }
    if (e == null || e > v.length){
      e = v.length;
    }
    // can't use .constructor in case user-supplied
    return u8.fromList(v.sublist(s, e));
  }

  Int32List crct = (() {
    final t = Int32List(256);
    for (int i = 0; i < 256; ++i) {
      int c = i, k = 9;
      while (--k >= 0){
        int result1 = ((c & 1) != 0 && -306674912 != 0) ? -306674912 : (c & 1);
        c = result1 ^ (c >>> 1);
      }
      t[i] = c;
    }
    return t;
  })();

  dopt(dynamic dat, Map opt, pre, post, [Map? st]) {
    if (st == null) {
      st = { 'l': 1 };
      if (opt['dictionary'] != null) {
        var dict = opt['dictionary'].sublist(-32768);
        u8 newDat = u8(dict.length + dat.length);
        newDat.setAll(0,dict);
        newDat[dat] = dict.length;
        dat = newDat;
        st['w'] = dict.length;
      }
    }
    return dflt(dat, opt['level'] == null ? 6 : opt['level'], opt['mem'] == null ? (st['l'] != 0? (math.max(8, math.min(13, math.log(dat.length))) * 1.5).ceil() : 20) : (12 + opt['mem']), pre, post, st);
  }

  dflt(List dat, int lvl, plvl, pre, int post, Map st) {
    int s = st['z'] ?? dat.length;
    u8 o = u8(pre + s + 5 * (1 + (s / 7000)).ceil() + post);
    // writing to this writes to the output buffer
    u8 w = o.sublist(pre, o.length - post);
    var lst = st['l'];
    int pos = (st['r'] ?? 0) & 7;
    if (lvl != 0) {
      if (pos != 0){
        w[0] = st['r'] >> 3;
      }
      var opt = deo[lvl - 1];
      int n = opt >> 13, c = opt & 8191;
      int msk_1 = (1 << plvl) - 1;
      //    prev 2-byte val map    curr 2-byte val map
      u16 prev = st['p'] ?? u16(32768), head = st['h'] ?? u16(msk_1 + 1);
      int bs1_1 = (plvl / 3).ceil(), bs2_1 = 2 * bs1_1;
      int hsh(i) { return (dat[i] ^ (dat[i + 1] << bs1_1) ^ (dat[i + 2] << bs2_1)) & msk_1; };
      // 24576 is an arbitrary number of maximum symbols per block
      // 424 buffer for last block
      i32 syms = i32(25000);
      // length/literal freq   distance freq
      u16 lf = u16(288), df = u16(32);
      //  l/lcnt  exbits  index          l/lind  waitdx          blkpos
      int lc_1 = 0, eb = 0, i = st['i'] ?? 0, li = 0, wi = st['w'] ?? 0, bs = 0;
      for (; i + 2 < s; ++i) {
        // hash value
        int hv = hsh(i);
        // index mod 32768    previous index mod
        int imod = i & 32767;
        var pimod = head[hv];
        prev[imod] = pimod;
        head[hv] = imod;
        // We always should modify head and prev, but only add symbols if
        // this data is not yet processed ("wait" for wait index)
        if (wi <= i) {
          // bytes remaining
          int rem = s - i;
          if ((lc_1 > 7000 || li > 24576) && (rem > 423 || lst == null)) {
            pos = wblk(dat, w, 0, syms, lf, df, eb, li, bs, i - bs, pos);
            li = lc_1 = eb = 0; bs = i;
            for (int j = 0; j < 286; ++j){
              lf[j] = 0;
            }
            for (int j = 0; j < 30; ++j){
              df[j] = 0;
            }
          }
          //  len    dist   chain
          int l = 2, d = 0, ch_1 = c, dif = imod - pimod & 32767;
          if (rem > 2 && hv == hsh(i - dif)) {
            int maxn = math.min<int>(n, rem) - 1;
            int maxd = math.min<int>(32767, i);
            // max possible length
            // not capped at dif because decompressors implement "rolling" index population
            int ml = math.min<int>(258, rem);
            while (dif <= maxd && --ch_1 >= 0 && imod != pimod) {
              if (dat[i + l] == dat[i + l - dif]) {
                int nl = 0;
                for (; nl < ml && dat[i + nl] == dat[i + nl - dif]; ++nl);
                if (nl > l) {
                  l = nl; d = dif;
                  // break out early when we reach "nice" (we are satisfied enough)
                  if (nl > maxn){
                    break;
                  }
                  // now, find the rarest 2-byte sequence within this
                  // length of literals and search for that instead.
                  // Much faster than just using the start
                  int mmd = math.min<int>(dif, nl - 2);
                  int md = 0;
                  for (int j = 0; j < mmd; ++j) {
                    int ti = i - dif + j & 32767;
                    int pti = prev[ti];
                    int cd = ti - pti & 32767;
                    if (cd > md){
                      md = cd;
                      pimod = ti;
                    }
                  }
                }
              }
              // check the previous match
              imod = pimod;
              pimod = prev[imod];
              dif += imod - pimod & 32767;
            }
          }
          // d will be nonzero only when a match was found
          if (d != 0) {
            // store both dist and len data in one int32
            // Make sure this is recognized as a len/dist with 28th bit (2^28)
            syms[li++] = 268435456 | (revfl[l] << 18) | revfd[d];
            int lin = revfl[l] & 31, din = revfd[d] & 31;
            eb += fleb[lin] + fdeb[din];
            ++lf[257 + lin];
            ++df[din];
            wi = i + l;
            ++lc_1;
          }
          else {
            syms[li++] = dat[i];
            ++lf[dat[i]];
          }
        }
      }
      for (i = math.max<int>(i, wi); i < s; ++i) {
          syms[li++] = dat[i];
          ++lf[dat[i]];
      }
      pos = wblk(dat, w, lst, syms, lf, df, eb, li, bs, i - bs, pos);
      if (lst == null) {
        st['r'] = (pos & 7) | w[(pos ~/ 8) | 0] << 3;
        // shft(pos) now 1 less if pos & 7 != 0
        pos -= 7;
        st['h'] = head;
        st['p'] = prev;
        st['i'] = i;
        st['w'] = wi;
      }
    }
    else {
      for (int i = st['w'] ?? 0; i < s + lst; i += 65535) {
        // end
        int e = i + 65535;
        if (e >= s) {
          // write final block
          w[(pos ~/ 8) | 0] = lst;
          e = s;
        }
        pos = wfblk(w, pos + 1, dat.sublist(i, e));
      }
      st['i'] = s;
    }
    return slc(o, 0, pre + shft(pos) + post);
  }

  wblk(List dat, List<int> out, int fineL, List syms, List<int> lf, List<int> df, int eb, int li,int bs, int bl, p) {
    wbits(out, p++, fineL);
    ++lf[256];
    var _a = hTree(lf, 15), dlt = _a['t'], mlb = _a['l'];
    var _b = hTree(df, 15), ddt = _b['t'], mdb = _b['l'];
    var _c = lc(dlt), lclt = _c['c'], nlc = _c['n'];
    var _d = lc(ddt), lcdt = _d['c'], ndc = _d['n'];
    u16 lcfreq = u16(19);
    for (int i = 0; i < lclt.length; ++i){
      ++lcfreq[lclt[i] & 31];
    }
    for (int i = 0; i < lcdt.length; ++i){
      ++lcfreq[lcdt[i] & 31];
    }
    var _e = hTree(lcfreq, 7), lct = _e['t'], mlcb = _e['l'];
    int nlcc = 19;
    for (; nlcc > 4 && (lct[clim[nlcc - 1]] == null); --nlcc);
    int flen = (bl + 5) << 3;
    var ftlen = clen(lf, flt) + clen(df, fdt) + eb;
    var dtlen = clen(lf, dlt) + clen(df, ddt) + eb + 14 + 3 * nlcc + clen(lcfreq, lct) + 2 * lcfreq[16] + 3 * lcfreq[17] + 7 * lcfreq[18];
    if (bs >= 0 && flen <= ftlen && flen <= dtlen){
      return wfblk(out, p, dat.sublist(bs, bs + bl));
    }
    var lm, ll, dm, dl;
    wbits(out, p, 1 + (dtlen < ftlen ? 1 : 0));//1 + (dtlen < ftlen));
    p += 2;
    if (dtlen < ftlen) {
      lm = hMap(dlt, mlb, 0);
      ll = dlt;
      dm = hMap(ddt, mdb, 0);
      dl = ddt;
      var llm = hMap(lct, mlcb, 0);
      wbits(out, p, nlc - 257);
      wbits(out, p + 5, ndc - 1);
      wbits(out, p + 10, nlcc - 4);
      p += 14;
      for (int i = 0; i < nlcc; ++i){
        wbits(out, p + 3 * i, lct[clim[i]]);
      }
      p += 3 * nlcc;
      var lcts = [lclt, lcdt];
      for (int it = 0; it < 2; ++it) {
        var clct = lcts[it];
        for (int i = 0; i < clct.length; ++i) {
          int len = clct[i] & 31;
          wbits(out, p, llm[len]);
          p += lct[len];
          if (len > 15){
            wbits(out, p, (clct[i] >> 5) & 127);
            p += clct[i] >> 12;
          }
        }
      }
    }
    else {
      lm = flm;
      ll = flt;
      dm = fdm;
      dl = fdt;
    }
      for (int i = 0; i < li; ++i) {
        var sym = syms[i];
        if (sym > 255) {
            int len = (sym >> 18) & 31;
            wbits16(out, p, lm[len + 257]);
            p += ll[len + 257];
            if (len > 7){
              wbits(out, p, (sym >> 23) & 31);
              p += fleb[len];
            }
            int dst = sym & 31;
            wbits16(out, p, dm[dst]);
            p += dl[dst];
            if (dst > 3){
              wbits16(out, p, (sym >> 5) & 8191);
              p += fdeb[dst];
            }
        }
        else {
          wbits16(out, p, lm[sym]);
          p += ll[sym];
        }
      }
      wbits16(out, p, lm[256]);
      return p + ll[256];
  }

  Map<String,dynamic> freb(List eb, int start) {
    u16 b = u16(31);
    for (int i = 0; i < 31; ++i) {
      b[i] = start += 1 << eb[i - 1];
    }
    // numbers here are at max 18 bits
    i32 r = i32(b[30]);
    for (int i = 1; i < 30; ++i) {
      for (int j = b[i]; j < b[i + 1]; ++j) {
        r[j] = ((j - b[i]) << 5) | i;
      }
    }
    return { 'b': b, 'r': r };
  }

  int wfblk(List out, int pos, List dat) {
    // no need to write 00 as type: TypedArray defaults to 0
    int s = dat.length;
    int o = shft(pos + 2);
    out[o] = s & 255;
    out[o + 1] = s >> 8;
    out[o + 2] = out[o] ^ 255;
    out[o + 3] = out[o + 1] ^ 255;
    for (int i = 0; i < s; ++i){
      out[o + i + 4] = dat[i];
    }
    return (o + 4 + s) * 8;
  }

  int shft(int p) { return ((p + 7) ~/ 8) | 0; }

  void wbits(List<int> d, int p, int v) {
    v <<= p & 7;
    int o = (p ~/ 8) | 0;
    d[o] |= v;
    d[o + 1] |= v >> 8;
  }

  void wbits16(List<int> d, int p, int v) {
    v <<= p & 7;
    int o = (p ~/ 8) | 0;
    d[o] |= v;
    d[o + 1] |= v >> 8;
    d[o + 2] |= v >> 16;
  }

  Map<String,dynamic> lc(List<int> c) {
    int s = c.length;
    // Note that the semicolon was intentional
    while (s != 0 && c[--s] == 0);
    u16 cl = u16(++s);
    //  ind      num         streak
    int cli = 0, cln = c[0], cls = 1;
    void w(v){ cl[cli++] = v; };
    for (int i = 1; i <= s; ++i) {
      if (c[i] == cln && i != s){
        ++cls;
      }
      else {
        if (cln == 0 && cls > 2) {
          for (; cls > 138; cls -= 138){
            w(32754);
          }
          if (cls > 2) {
            w(cls > 10 ? ((cls - 11) << 5) | 28690 : ((cls - 3) << 5) | 12305);
            cls = 0;
          }
        }
        else if (cls > 3) {
          w(cln);
          --cls;
          for (; cls > 6; cls -= 6){
            w(8304);
          }
          if (cls > 2){
            w(((cls - 3) << 5) | 8208);
            cls = 0;
          }
        }
        while (cls-- >= 0){
          w(cln);
        }
        cls = 1;
        cln = c[i];
      }
    }
    return { 'c': cl.sublist(0, cli), 'n': s };
  }

  int clen(List<int> cf, List<int> cl) {
    int l = 0;
    for (int i = 0; i < cl.length; ++i){
      l += cf[i] * cl[i];
    }
    return l;
  }

  u16 hMap(List cd, int mb, int r) {
    int s = cd.length;
    // index
    int i = 0;
    // u16 "map": index -> # of codes with bit length = index
    u16 l = u16(mb);
    // length of cd must be 288 (total # of codes)
    for (; i < s; ++i) {
      if (cd[i] != null){
        ++l[cd[i] - 1];
      }
    }
    // u16 "map": index -> minimum code for bit length = index
    u16 le = u16(mb);
    for (i = 1; i < mb; ++i) {
      le[i] = (le[i - 1] + l[i - 1]) << 1;
    }
    late u16 co;
    if (r != 0) {
      // u16 "map": index -> number of actual bits, symbol for code
      co = u16(1 << mb);
      // bits to remove for reverser
      int rvb = 15 - mb;
      for (i = 0; i < s; ++i) {
        // ignore 0 lengths
        if (cd[i] != null) {
          // num encoding both symbol and bits read
          int sv = (i << 4) | cd[i];
          // free bits
          int r_1 = mb - (cd[i] as int);
          // start value
          int v = le[cd[i] - 1]++ << r_1;
          // m is end value
          for (int m = v | ((1 << r_1) - 1); v <= m; ++v) {
            // every 16 bit value starting with the code yields the same result
            co[rev[v] >> rvb] = sv;
          }
        }
      }
    }
    else {
      co = u16(s);
      for (i = 0; i < s; ++i) {
        if (cd[i] != 0) {
          co[i] = rev[le[cd[i] - 1]++] >> (15 - (cd[i] as int));
        }
      }
    }
    return co;
  }

  Map<String,dynamic> hTree(List<int> d, int mb) {
      // Need extra info to make a tree
      List<Map<String,dynamic>> t = [];
      for (int i = 0; i < d.length; ++i) {
        if (d[i] != 0){
          t.add({ 's': i, 'f': d[i] });
        }
      }
      int s = t.length;
      var t2 = t.removeLast();//.slice();
      if (s == 0){
        return { 't': et, 'l': 0 };
      }
      if (s == 1) {
        u8 v = u8(t[0]['s'] + 1);
        v[t[0]['s']] = 1;
        return { 't': v, 'l': 1 };
      }
      t.sort((a, b) { return a['f'] - b['f']; });
      // after i2 reaches last ind, will be stopped
      // freq must be greater than largest possible number of symbols
      t.add({ 's': -1, 'f': 25001 });
      var l = t[0], r = t[1];
      int i0 = 0, i1 = 1, i2 = 2;
      t[0] = { 's': -1, 'f': l['f'] + r['f'], 'l': l, 'r': r };
      // efficient algorithm from UZIP.js
      // i0 is lookbehind, i2 is lookahead - after processing two low-freq
      // symbols that combined have high freq, will start processing i2 (high-freq,
      // non-composite) symbols instead
      // see https://reddit.com/r/photopea/comments/ikekht/uzipjs_questions/
      while (i1 != s - 1) {
        l = t[t[i0]['f'] < t[i2]['f'] ? i0++ : i2++];
        r = t[i0 != i1 && t[i0]['f'] < t[i2]['f'] ? i0++ : i2++];
        t[i1++] = { 's': -1, 'f': l['f'] + r['f'], 'l': l, 'r': r };
      }
      int maxSym = t2[0]['s'];
      for (int i = 1; i < s; ++i) {
        if (t2[i]['s'] > maxSym){
          maxSym = t2[i]['s'];
        }
      }
      // code lengths
      u16 tr = u16(maxSym + 1);
      // max bits in tree
      int mbt = ln(t[i1 - 1], tr, 0);
      if (mbt > mb) {
        // more algorithms from UZIP.js
        // TODO: find out how this code works (debt)
        //  ind    debt
        int i = 0, dt = 0;
        //    left            cost
        int lft = mbt - mb;
        int cst = 1 << lft;
        //t2.sort((a, b) { return tr[b['s']] - tr[a['s']] ?? a['f'] - b['f']; });
        {
          List<MapEntry<String,dynamic>> sortedEntries = t2.entries.toList();
          sortedEntries.sort((a, b) { final i = tr[b.value['s']] - tr[a.value['s']]; return i != 0 ?i:a.value['f'] - b.value['f']; });
        t2 = Map.fromEntries(sortedEntries);
        }
        for (; i < s; ++i) {
          int i2_1 = t2[i]['s'];
          if (tr[i2_1] > mb) {
            dt += cst - (1 << (mbt - tr[i2_1]));
            tr[i2_1] = mb;
          }
          else{
            break;
          }
        }
        dt >>= lft;
        while (dt > 0) {
          int i2_2 = t2[i]['s'];
          if (tr[i2_2] < mb){
            dt -= 1 << (mb - tr[i2_2]++ - 1);
          }
          else{
            ++i;
          }
        }
      for (; i >= 0 && dt != 0; --i) {
        int i2_3 = t2[i]['s'];
        if (tr[i2_3] == mb) {
          --tr[i2_3];
          ++dt;
        }
      }
      mbt = mb;
    }
    return { 't': u8.fromList(tr), 'l': mbt };
  }

  int ln(Map<String,dynamic> n, List<int> l, int d) {
    return n['s'] == -1
      ? math.max<int>(ln(n['l'], l, d + 1), ln(n['r'], l, d + 1))
      : (l[n['s']] = d);
  }
}