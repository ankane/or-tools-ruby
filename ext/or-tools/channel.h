#pragma once

#include <chrono>
#include <condition_variable>
#include <mutex>
#include <optional>
#include <queue>

template<typename T>
class Channel {
  std::queue<T> queue;
  std::mutex mutex;
  std::condition_variable cv;

public:
  void send(T message) {
    std::lock_guard<std::mutex> guard(mutex);
    queue.push(message);
    cv.notify_one();
  }

  template<typename U, typename V>
  std::optional<T> recv_timeout(const std::chrono::duration<U, V>& duration) {
    T message;
    std::unique_lock<std::mutex> lock(mutex);
    auto time = std::chrono::system_clock::now() + duration;
    if (!cv.wait_until(lock, time, [&] { return !queue.empty(); })) {
      return std::nullopt;
    }
    message = std::move(queue.front());
    queue.pop();
    return message;
  }

  bool empty() {
    std::lock_guard<std::mutex> guard(mutex);
    return queue.empty();
  }
};
