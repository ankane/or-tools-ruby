#pragma once

#include <rice/rice.hpp>
#include <rice/stl.hpp>

// TODO remove
namespace Rice::detail
{
  template<>
  struct Type<Rice::Symbol>
  {
    static bool verify()
    {
      return true;
    }
  };
}
