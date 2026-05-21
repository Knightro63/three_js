/**
 * Abstract base class of a timestamp query pool.
 *
 * @abstract
 */
abstract class TimestampQueryPool {
  int maxQueries;
	bool trackTimestamp = true;
	int currentQueryIndex = 0;
	Map<String,num> queryOffsets = {};
	bool isDisposed = false;
	double lastValue = 0;
	bool pendingResolve = false;
	TimestampQueryPool([this.maxQueries = 256 ]);

	double? allocateQueriesForContext( /* renderContext */ );
	Future<double> resolveQueriesAsync();
	void dispose() {}
}
