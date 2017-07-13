
BIRDCAST_HOME  = getenv('BIRDCAST_HOME');

input_dir      = '/home/sgabriel/scans';
cluttermap_dir = sprintf('%s/radar/clutterMaps', BIRDCAST_HOME);
weather_dir    = sprintf('%s/NARR/data', BIRDCAST_HOME);
output_root    = '/home/sgabriel/cajun_output';

run_cajun(input_dir, weather_dir, output_root, cluttermap_dir, varargin{:});