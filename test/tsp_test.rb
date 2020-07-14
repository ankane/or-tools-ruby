require_relative "test_helper"

class TSPTest < Minitest::Test
  def test_works
    locations = [
      {id: "Tokyo", latitude: 35.6762, longitude: 139.6503},
      {id: "Delhi", latitude: 28.7041, longitude: 77.1025},
      {id: "Shanghai", latitude: 31.2304, longitude: 121.4737},
      {id: "São Paulo", latitude: -23.5505, longitude: -46.6333},
      {id: "Mexico City", latitude: 19.4326, longitude: -99.1332},
      {id: "Cairo", latitude: 30.0444, longitude: 31.2357},
      {id: "Mumbai", latitude: 19.0760, longitude: 72.8777},
      {id: "Beijing", latitude: 39.9042, longitude: 116.4074},
      {id: "Dhaka", latitude: 23.8103, longitude: 90.4125},
      {id: "Osaka", latitude: 34.6937, longitude: 135.5023},
      {id: "New York City", latitude: 40.7128, longitude: -74.0060},
      {id: "Karachi", latitude: 24.8607, longitude: 67.0011},
      {id: "Buenos Aires", latitude: -34.6037, longitude: -58.3816}
    ]
    tsp = ORTools::TSP.new(locations)
    expected_route = ["Tokyo", "Osaka", "Shanghai", "Beijing", "Dhaka", "Delhi", "Mumbai", "Karachi", "Cairo", "São Paulo", "Buenos Aires", "Mexico City", "New York City", "Tokyo"]
    assert_equal expected_route, tsp.route
    assert tsp.distances
    assert tsp.distances.sum
  end
end
