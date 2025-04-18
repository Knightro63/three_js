@JS('THREE')
import 'dart:js_interop';

@JS('Layers')
class Layers {
  external int mask;
  external Layers();

  external void set(int channel);
  external void enable(int channel);
  external void enableAll();
  external void toggle(int channel);
  external void disable(int channel);
  external void disableAll();
  external bool test(Layers layers);
  external bool isEnabled(int channel);
}
