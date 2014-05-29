SGVAppearanceProxy
==================

An UIAppearance proxy wrapper to work around performance issues on iOS7.

UIAppearance performs slow under iOS7 because of some internal changes: certain setter methods (those with axis values or those with more than one argument) end up calling an expensive method_exchageImplementations() function.

This proxy wraps around original appearance proxy and uses the message forwarding mechanism of Objective-C to translate the affected method calls into methods with a single argument, and then passes them along to the original proxy, thus mitigating the problem.

### Caveats

This only works for UIView subclasses. Non-UIView UIAppearance-enabled classes like UIBarButtonitem have their UIAppearance proxies send invocations to a private UIView subclass, so it is not possible to legally add new methods to them to pull the same trick. 
