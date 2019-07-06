#include <muduo/base/Logging.h>
#include <errno.h>

using namespace muduo;

int main()
{
	LogStream s;
	Fmt  fmt("%.6f",1.23);
	operator<<(s,fmt);
	LOG_TRACE<<"trace ...";
	LOG_DEBUG<<"debug ...";
	LOG_INFO<<"info ...";
	LOG_WARN<<"warn ...";
	LOG_ERROR<<"error ...";
	//LOG_FATAL<<"fatal ...";
	errno = 13;
	LOG_SYSERR<<"syserr ...";
	LOG_SYSFATAL<<"sysfatal ...";
	return 0;
}
