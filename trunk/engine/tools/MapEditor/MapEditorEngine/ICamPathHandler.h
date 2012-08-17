#pragma once


namespace sqr
{
	class ICamPathHandler
	{
	public:
		virtual void OnKeyChanged() = 0;
		virtual void OnAnimEnd() = 0;
	};
}