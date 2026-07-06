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
    std::unique_lock<std::mutex> lock(mutex);
    if (!cv.wait_for(lock, duration, [&] { return !queue.empty(); })) {
      return std::nullopt;
    }
    T message = std::move(queue.front());
    queue.pop();
    return message;
  }

  bool empty() {
    std::lock_guard<std::mutex> guard(mutex);
    return queue.empty();
  }
};
