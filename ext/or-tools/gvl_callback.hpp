#pragma once

#include <condition_variable>
#include <deque>
#include <memory>
#include <mutex>
#include <thread>

#include <ortools/sat/cp_model.h>
#include <rice/rice.hpp>
#include <ruby/thread.h>

namespace {

struct ORToolsRubyCallbackQueue {
  std::mutex mutex;
  std::condition_variable cv;
  std::deque<operations_research::sat::CpSolverResponse> responses;
  bool solver_finished = false;
  bool has_final_response = false;
  operations_research::sat::CpSolverResponse final_response;
};

struct ORToolsRubyWaitForEventArgs {
  ORToolsRubyCallbackQueue* queue;
  bool has_response = false;
  operations_research::sat::CpSolverResponse response;
};

static void* ortools_ruby_wait_for_event_without_gvl(void* ptr) {
  auto* args = static_cast<ORToolsRubyWaitForEventArgs*>(ptr);
  std::unique_lock<std::mutex> lock(args->queue->mutex);
  args->queue->cv.wait(lock, [args]() {
    return args->queue->solver_finished || !args->queue->responses.empty();
  });

  if (!args->queue->responses.empty()) {
    args->response = args->queue->responses.front();
    args->queue->responses.pop_front();
    args->has_response = true;
  } else {
    args->has_response = false;
  }

  return nullptr;
}

static operations_research::sat::CpSolverResponse ortools_ruby_solve_cp_model_without_gvl(
  const operations_research::sat::CpModelProto* proto,
  operations_research::sat::Model* model
) {
  return operations_research::sat::SolveCpModel(*proto, model);
}

static operations_research::sat::CpSolverResponse ortools_ruby_solve_cp_model_no_callback(
  const operations_research::sat::CpModelProto& proto,
  operations_research::sat::Model& solver_model
) {
  return Rice::detail::no_gvl(
    &ortools_ruby_solve_cp_model_without_gvl,
    &proto,
    &solver_model
  );
}

static operations_research::sat::CpSolverResponse ortools_ruby_solve_cp_model_with_callback(
  const operations_research::sat::CpModelProto& proto,
  operations_research::sat::Model& solver_model,
  Rice::Object callback
) {
  VALUE rb_cb = callback.value();
  rb_gc_register_address(&rb_cb);

  auto callback_queue = std::make_shared<ORToolsRubyCallbackQueue>();

  solver_model.Add(operations_research::sat::NewFeasibleSolutionObserver(
    [callback_queue](const operations_research::sat::CpSolverResponse& r) {
      std::lock_guard<std::mutex> lock(callback_queue->mutex);
      callback_queue->responses.push_back(r);
      callback_queue->cv.notify_one();
    })
  );

  std::thread solver_thread([&proto, &solver_model, callback_queue]() {
    auto response = ortools_ruby_solve_cp_model_without_gvl(&proto, &solver_model);
    {
      std::lock_guard<std::mutex> lock(callback_queue->mutex);
      callback_queue->final_response = response;
      callback_queue->has_final_response = true;
      callback_queue->solver_finished = true;
    }
    callback_queue->cv.notify_all();
  });

  operations_research::sat::CpSolverResponse final_response;

  try {
    Rice::Object rb_callback(rb_cb);

    while (true) {
      ORToolsRubyWaitForEventArgs wait_args{callback_queue.get()};
      rb_thread_call_without_gvl(
        ortools_ruby_wait_for_event_without_gvl,
        &wait_args,
        RUBY_UBF_IO,
        nullptr
      );

      if (wait_args.has_response) {
        Rice::Data_Object<operations_research::sat::CpSolverResponse> rb_response(
          new operations_research::sat::CpSolverResponse(wait_args.response)
        );
        rb_callback.call("response=", rb_response);
        rb_callback.call("on_solution_callback");
      }

      bool done = false;
      {
        std::lock_guard<std::mutex> lock(callback_queue->mutex);
        done = callback_queue->solver_finished && callback_queue->responses.empty();
      }

      if (done && !wait_args.has_response) {
        break;
      }
    }
  } catch (...) {
    solver_thread.join();
    rb_gc_unregister_address(&rb_cb);
    throw;
  }

  solver_thread.join();

  {
    std::lock_guard<std::mutex> lock(callback_queue->mutex);
    if (callback_queue->has_final_response) {
      final_response = callback_queue->final_response;
    }
  }

  rb_gc_unregister_address(&rb_cb);
  return final_response;
}

} // namespace
