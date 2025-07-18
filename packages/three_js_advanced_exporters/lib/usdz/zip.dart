import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:convert'; 

// aliases for shorter compressed code (most minifers don't do this)
typedef u8 = Uint8List;
typedef u16 = Uint16List;
typedef i32 = Int32List;

Uint8List fleb = new u8.fromList([0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0, /* unused */ 0, 0, /* impossible */ 0]);
// fixed distance extra bits
Uint8List fdeb = new u8.fromList([0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13, /* unused */ 0, 0]);
Int32List deo = i32.fromList([65540, 131080, 131088, 131104, 262176, 1048704, 1048832, 2114560, 2117632]);
Uint8List clim = new u8.fromList([16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15]);
var _a = freb(fleb, 2), fl = _a['b']..[28] = 258, revfl = _a['r']..[258] = 28;
var _b = freb(fdeb, 0), fd = _b['b'], revfd = _b['r'];

var et = /*#__PURE__*/ new u8(0);
var flt = new u8.fromList(List.filled(144, 8)+List.filled(256-144, 9)+List.filled(280-256, 7)+List.filled(288-280, 8));
var fdt = new u8.fromList(List.filled(32, 5));
var flm = /*#__PURE__*/ hMap(flt, 9, 0);
var fdm = /*#__PURE__*/ hMap(fdt, 5, 0);

var rev = new u16.fromList(List.generate(32768, (int i){
  var x = ((i & 0xAAAA) >> 1) | ((i & 0x5555) << 1);
  x = ((x & 0xCCCC) >> 2) | ((x & 0x3333) << 2);
  x = ((x & 0xF0F0) >> 4) | ((x & 0x0F0F) << 4);
  return (((x & 0xFF00) >> 8) | ((x & 0x00FF) << 8)) >> 1;
}));

zipSync(Map<String,dynamic> data, [Map<String,dynamic>? opts]) {
  opts ??= {};
  final Map<String,dynamic> r = {};
  List files = [];
  fltn(data, '', r, opts);
  var o = 0;
  var tot = 0;
  for (var fn in r.keys) {
    var _a = r[fn], file = _a[0];
    Map<String,dynamic> p = _a[1];
    var compression = (p['level'] ?? 0) == 0 ? 0 : 8;
    var f = strToU8(fn); 
    int s = f.length;
    var com = p['comment'] ?? 0;
    var m = (com != 0 && strToU8(com) != 0) ? strToU8(com) : com;//com && strToU8(com);
    int ms = (m != 0 && m.length != 0) ? m.length : m;//m && m.length;
    var exl = exfl(p['extra']);
    if (s > 65535){
      err(11);
    }
    var d = compression != 0? deflateSync(file, p) : file;
    int l = d.length;
    var c = crc();
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
    tot += 76 + 2 * (s + exl) + (ms ?? 0) + l;
  }
  var out = new u8(tot + 22), oe = o, cdl = tot - o;
  for (int i = 0; i < files.length; ++i) {
    Map f = files[i];
    wzh(out, f['o'], f, f['f'], f['u'], f['c'].length);
    var badd = 30 + f['f'].length + exfl(f['extra']);
    out[f['c']] = f['o'] + badd;
    wzh(out, o, f, f['f'], f['u'], f['c'].length, f['o'], f['m']);
    o += 16 + badd + (f['m'] != null? f['m'].length : 0) as int;
  }
  wzf(out, o, files.length, cdl, oe);
  return out;
}

fltn ( d, String p, Map<String,dynamic> t, Map<String,dynamic> o) {
  print(d.runtimeType);
  final List keys = d is Map?d.keys.toList():(d as List<int>).toList();
  for (final k in keys) {
    var val = d[k], n = p + k.toString(), op = o;
    if (val is List && val is! Uint8List){
      op = mrg(o, val[1]);
      val = val[0];
    }
    if (val is List<int>){
      t[n] = [val, op];
    }
    else {
      t[n += '/'] = [new u8(0), op];
      fltn(val, n, t, o);
    }
  }
}

Uint8List strToU8(String str, [bool latin1 = false]) {
  if (latin1) {
    var ar_1 = new u8(str.length);
    for (var i = 0; i < str.length; ++i){
      ar_1[i] = str.codeUnitAt(i);
    }
    return ar_1;
  }
  if (true){
    return utf8.encode(str);//te.encode(str);
  }

  // var l = str.length;
  // var ar = new u8(str.length + (str.length >> 1));
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

err(ind, [msg, nt]) {
  throw(msg ?? ec[ind]);
  // e.code = ind;
  // if (Error.captureStackTrace)
  //     Error.captureStackTrace(e, err);
  // if(!nt)
  //   throw e;
  // return e;
}

deflateSync(data, opts) {
  return dopt(data, opts ?? {}, 0, 0);
}

Map<String,Function> crc() {
  var c = -1;
  return {
    'p': (d) {
      // closures have awful performance
      var cr = c;
      for (var i = 0; i < d.length; ++i){
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

wzh(List<int> d, b, Map f, fn, u, c, [ce, co]) {
  var fl = fn.length, ex = f['extra'], col = (co != 0 && co?.length != 0) ? (co?.length ?? 0) : co;//co && co.length;
  var exl = exfl(ex);
  wbytes(d, b, ce != null ? 0x2014B50 : 0x4034B50);
  b += 4;
  if (ce != null){
    d[b++] = 20;
    d[b++] = f['os'];
  }
  d[b] = 20;
  b += 2; // spec compliance? what's that?
  d[b++] = ((f['flag'] ?? 0) << 1) | (c < 0 ? 8 : 0);//(c < 0 && 8);
  d[b++] = u != 0? 8 : u;//u && 8;
  d[b++] = f['compression'] & 255;
  d[b++] = f['compression'] >> 8;
  var dt = new DateTime.fromMillisecondsSinceEpoch(f['mtime'] == null ? DateTime.now().millisecondsSinceEpoch : f['mtime']), y = dt.year - 1980;
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
    wbytes(d, b + 6, f['attrs']);
    wbytes(d, b + 10, ce);
    b += 14;
  }
  d[fn] = b;
  b += fl;
  if (exl != 0) {
    for (final k in ex) {
      var exf = ex[k], l = exf.length;
      wbytes(d, b, k);
      wbytes(d, b + 2, l);
      d[exf] = b + 4;
      b += 4 + l;
    }
  }
  if (col != 0){
    d[co] = b; 
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

slc(v, s, e) {
  if (s == null || s < 0){
    s = 0;
  }
  if (e == null || e > v.length){
    e = v.length;
  }
  // can't use .constructor in case user-supplied
  return new u8(v.subarray(s, e));
}

var crct = (() {
  final t = new Int32List(256);
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

dopt(dat, Map opt, pre, post, [st]) {
  if (st == null) {
    st = { 'l': 1 };
    if (opt['dictionary']) {
      var dict = opt['dictionary'].subarray(-32768);
      var newDat = new u8(dict.length + dat.length);
      newDat.setAll(0,dict);
      newDat[dat] = dict.length;
      dat = newDat;
      st.w = dict.length;
    }
  }
  return dflt(dat, opt['level'] == null ? 6 : opt['level'], opt['mem'] == null ? (st.l ? (math.max(8, math.min(13, math.log(dat.length))) * 1.5).ceil() : 20) : (12 + opt['mem']), pre, post, st);
}

dflt(dat, lvl, plvl, pre, int post, st) {
  var s = st.z ?? dat.length;
  var o = new u8(pre + s + 5 * (1 + (s / 7000)).ceil() + post);
  // writing to this writes to the output buffer
  var w = o.sublist(pre, o.length - post);
  var lst = st.l;
  var pos = (st.r ?? 0) & 7;
  if (lvl) {
    if (pos){
      w[0] = st.r >> 3;
    }
    var opt = deo[lvl - 1];
    var n = opt >> 13, c = opt & 8191;
    var msk_1 = (1 << plvl) - 1;
    //    prev 2-byte val map    curr 2-byte val map
    var prev = st.p ?? new u16(32768), head = st.h ?? new u16(msk_1 + 1);
    var bs1_1 = (plvl / 3).ceil(), bs2_1 = 2 * bs1_1;
    var hsh = (i) { return (dat[i] ^ (dat[i + 1] << bs1_1) ^ (dat[i + 2] << bs2_1)) & msk_1; };
    // 24576 is an arbitrary number of maximum symbols per block
    // 424 buffer for last block
    var syms = new i32(25000);
    // length/literal freq   distance freq
    var lf = new u16(288), df = new u16(32);
    //  l/lcnt  exbits  index          l/lind  waitdx          blkpos
    var lc_1 = 0, eb = 0, i = st.i ?? 0, li = 0, wi = st.w ?? 0, bs = 0;
    for (; i + 2 < s; ++i) {
      // hash value
      var hv = hsh(i);
      // index mod 32768    previous index mod
      var imod = i & 32767, pimod = head[hv];
      prev[imod] = pimod;
      head[hv] = imod;
      // We always should modify head and prev, but only add symbols if
      // this data is not yet processed ("wait" for wait index)
      if (wi <= i) {
        // bytes remaining
        var rem = s - i;
        if ((lc_1 > 7000 || li > 24576) && (rem > 423 || !lst)) {
          pos = wblk(dat, w, 0, syms, lf, df, eb, li, bs, i - bs, pos);
          li = lc_1 = eb = 0; bs = i;
          for (var j = 0; j < 286; ++j){
            lf[j] = 0;
          }
          for (var j = 0; j < 30; ++j){
            df[j] = 0;
          }
        }
        //  len    dist   chain
        var l = 2, d = 0, ch_1 = c, dif = imod - pimod & 32767;
        if (rem > 2 && hv == hsh(i - dif)) {
          var maxn = math.min<int>(n, rem) - 1;
          var maxd = math.min<int>(32767, i);
          // max possible length
          // not capped at dif because decompressors implement "rolling" index population
          var ml = math.min<int>(258, rem);
          while (dif <= maxd && --ch_1 >= 0 && imod != pimod) {
            if (dat[i + l] == dat[i + l - dif]) {
              var nl = 0;
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
                var mmd = math.min<int>(dif, nl - 2);
                var md = 0;
                for (var j = 0; j < mmd; ++j) {
                  var ti = i - dif + j & 32767;
                  var pti = prev[ti];
                  var cd = ti - pti & 32767;
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
    if (!lst) {
      st.r = (pos & 7) | w[(pos / 8) | 0] << 3;
      // shft(pos) now 1 less if pos & 7 != 0
      pos -= 7;
      st.h = head;
      st.p = prev;
      st.i = i;
      st.w = wi;
    }
  }
  else {
    for (var i = st.w ?? 0; i < s + lst; i += 65535) {
      // end
      var e = i + 65535;
      if (e >= s) {
        // write final block
        w[(pos / 8) | 0] = lst;
        e = s;
      }
      pos = wfblk(w, pos + 1, dat.subarray(i, e));
    }
    st.i = s;
  }
  return slc(o, 0, pre + shft(pos) + post);
}

wblk(dat, out, fineL, syms, lf, df, eb, li, bs, bl, p) {
  wbits(out, p++, fineL);
  ++lf[256];
  var _a = hTree(lf, 15), dlt = _a['t'], mlb = _a['l'];
  var _b = hTree(df, 15), ddt = _b['t'], mdb = _b['l'];
  var _c = lc(dlt), lclt = _c['c'], nlc = _c['n'];
  var _d = lc(ddt), lcdt = _d['c'], ndc = _d['n'];
  var lcfreq = new u16(19);
  for (var i = 0; i < lclt.length; ++i){
    ++lcfreq[lclt[i] & 31];
  }
  for (var i = 0; i < lcdt.length; ++i){
    ++lcfreq[lcdt[i] & 31];
  }
  var _e = hTree(lcfreq, 7), lct = _e['t'], mlcb = _e['l'];
  var nlcc = 19;
  for (; nlcc > 4 && !lct[clim[nlcc - 1]]; --nlcc);
  var flen = (bl + 5) << 3;
  var ftlen = clen(lf, flt) + clen(df, fdt) + eb;
  var dtlen = clen(lf, dlt) + clen(df, ddt) + eb + 14 + 3 * nlcc + clen(lcfreq, lct) + 2 * lcfreq[16] + 3 * lcfreq[17] + 7 * lcfreq[18];
  if (bs >= 0 && flen <= ftlen && flen <= dtlen){
    return wfblk(out, p, dat.subarray(bs, bs + bl));
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
    for (var i = 0; i < nlcc; ++i){
      wbits(out, p + 3 * i, lct[clim[i]]);
    }
    p += 3 * nlcc;
    var lcts = [lclt, lcdt];
    for (var it = 0; it < 2; ++it) {
      var clct = lcts[it];
      for (var i = 0; i < clct.length; ++i) {
        var len = clct[i] & 31;
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
    for (var i = 0; i < li; ++i) {
      var sym = syms[i];
      if (sym > 255) {
          var len = (sym >> 18) & 31;
          wbits16(out, p, lm[len + 257]);
          p += ll[len + 257];
          if (len > 7){
            wbits(out, p, (sym >> 23) & 31);
            p += fleb[len];
          }
          var dst = sym & 31;
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

Map<String,dynamic> freb(eb, int start) {
  var b = new u16(31);
  for (var i = 0; i < 31; ++i) {
    b[i] = start += 1 << eb[i - 1];
  }
  // numbers here are at max 18 bits
  var r = new i32(b[30]);
  for (var i = 1; i < 30; ++i) {
    for (var j = b[i]; j < b[i + 1]; ++j) {
      r[j] = ((j - b[i]) << 5) | i;
    }
  }
  return { 'b': b, 'r': r };
}

int wfblk(out, pos, dat) {
  // no need to write 00 as type: TypedArray defaults to 0
  int s = dat.length;
  int o = shft(pos + 2);
  out[o] = s & 255;
  out[o + 1] = s >> 8;
  out[o + 2] = out[o] ^ 255;
  out[o + 3] = out[o + 1] ^ 255;
  for (var i = 0; i < s; ++i){
    out[o + i + 4] = dat[i];
  }
  return (o + 4 + s) * 8;
}

int shft(int p) { return ((p + 7) ~/ 8) | 0; }

wbits(d, p, v) {
  v <<= p & 7;
  int o = (p ~/ 8) | 0;
  d[o] |= v;
  d[o + 1] |= v >> 8;
}

wbits16(d, p, v) {
  v <<= p & 7;
  int o = (p ~/ 8) | 0;
  d[o] |= v;
  d[o + 1] |= v >> 8;
  d[o + 2] |= v >> 16;
}

Map<String,dynamic> lc(c) {
  var s = c.length;
  // Note that the semicolon was intentional
  while (s != 0 && c[--s] == 0);
  var cl = new u16(++s);
  //  ind      num         streak
  var cli = 0, cln = c[0], cls = 1;
  var w = (v) { cl[cli++] = v; };
  for (var i = 1; i <= s; ++i) {
    if (c[i] == cln && i != s){
      ++cls;
    }
    else {
      if (!cln && cls > 2) {
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

int clen(cf, cl) {
  int l = 0;
  for (var i = 0; i < cl.length; ++i){
    l += (cf[i] as int) * (cl[i] as int);
  }
  return l;
}

var hMap = ((cd, int mb, r) {
  var s = cd.length;
  // index
  var i = 0;
  // u16 "map": index -> # of codes with bit length = index
  var l = new u16(mb);
  // length of cd must be 288 (total # of codes)
  for (; i < s; ++i) {
    if (cd[i]){
      ++l[cd[i] - 1];
    }
  }
  // u16 "map": index -> minimum code for bit length = index
  var le = new u16(mb);
  for (i = 1; i < mb; ++i) {
    le[i] = (le[i - 1] + l[i - 1]) << 1;
  }
  var co;
  if (r) {
    // u16 "map": index -> number of actual bits, symbol for code
    co = new u16(1 << mb);
    // bits to remove for reverser
    var rvb = 15 - mb;
    for (i = 0; i < s; ++i) {
      // ignore 0 lengths
      if (cd[i]) {
        // num encoding both symbol and bits read
        var sv = (i << 4) | cd[i];
        // free bits
        int r_1 = mb - (cd[i] as int);
        // start value
        var v = le[cd[i] - 1]++ << r_1;
        // m is end value
        for (var m = v | ((1 << r_1) - 1); v <= m; ++v) {
          // every 16 bit value starting with the code yields the same result
          co[rev[v] >> rvb] = sv;
        }
      }
    }
  }
  else {
    co = new u16(s);
    for (i = 0; i < s; ++i) {
      if (cd[i]) {
        co[i] = rev[le[cd[i] - 1]++] >> (15 - (cd[i] as int));
      }
    }
  }
  return co;
});

Map<String,dynamic> hTree(d, int mb) {
    // Need extra info to make a tree
    List<Map<String,dynamic>> t = [];
    for (var i = 0; i < d.length; ++i) {
      if (d[i]){
        t.add({ 's': i, 'f': d[i] });
      }
    }
    var s = t.length;
    var t2 = t.removeLast();//.slice();
    if (s == 0){
      return { 't': et, 'l': 0 };
    }
    if (s == 1) {
      var v = new u8(t[0]['s'] + 1);
      v[t[0]['s']] = 1;
      return { 't': v, 'l': 1 };
    }
    t.sort((a, b) { return a['f'] - b['f']; });
    // after i2 reaches last ind, will be stopped
    // freq must be greater than largest possible number of symbols
    t.add({ 's': -1, 'f': 25001 });
    var l = t[0], r = t[1], i0 = 0, i1 = 1, i2 = 2;
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
    var maxSym = t2[0]['s'];
    for (var i = 1; i < s; ++i) {
      if (t2[i]['s'] > maxSym){
        maxSym = t2[i]['s'];
      }
    }
    // code lengths
    var tr = new u16(maxSym + 1);
    // max bits in tree
    int mbt = ln(t[i1 - 1], tr, 0);
    if (mbt > mb) {
      // more algorithms from UZIP.js
      // TODO: find out how this code works (debt)
      //  ind    debt
      var i = 0, dt = 0;
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
        var i2_1 = t2[i].s;
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
        var i2_2 = t2[i].s;
        if (tr[i2_2] < mb){
          dt -= 1 << (mb - tr[i2_2]++ - 1);
        }
        else{
          ++i;
        }
      }
    for (; i >= 0 && dt != 0; --i) {
      var i2_3 = t2[i].s;
      if (tr[i2_3] == mb) {
        --tr[i2_3];
        ++dt;
      }
    }
    mbt = mb;
  }
  return { 't': u8.fromList(tr), 'l': mbt };
}

int ln(Map<String,dynamic> n, l, d) {
  return n['s'] == -1
    ? math.max<int>(ln(n['l'], l, d + 1), ln(n['r'], l, d + 1))
    : (l[n['s']] = d);
}