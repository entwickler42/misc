/*
 * c++ functor demo
 */

#include <iostream>
#include <string>

using namespace std;

class functor
{
	public:
		functor(const string& text)
			: buffer(text)
		{}

		int operator()()
		{ 
			cout << buffer << endl;
			return 0;
		}

	private:
		string buffer;
};

class somestatic
{
	public:
		template<typename T> static int call(T f)
		{
			return f();
		}
};

int print_func()
{
	cout << "Hello Horld old-style" << endl;
}

template<typename T> void call_t(T f)
{
	f();
}

int main(int argc, char* argv[])
{
	call_t(functor("Hello World"));
	call_t(print_func);

	somestatic::call(functor("Hello World (and i'am dynamic :P)"));
	somestatic::call(print_func);

	return 0;
}
