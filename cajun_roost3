station = 'KDOX'
radar_path = '~/scans/KDOX20111001_111742_V04.gz';

p = inputParser;

%%% CONSTANTS AND DEFAULT VALUES %%%

DEFAULT_SEG_SCALE = 0.4;

% label used in the segmenter for rain
SEG_RAIN_LABEL = 0;

%%% INPUT DEFINITIONS %%%

addRequired(p, 'radar_path', @ischar);
addRequired(p, 'station',    @ischar);
addParameter(p, 'wind_path',         '',    @ischar);
addParameter(p, 'clutter_path',      '',    @ischar);
addParameter(p, 'seg_net_path',      '',    @ischar);
addParameter(p, 'max_elev',          5,     @isinteger);
addParameter(p, 'rmin_m',            5000,  @isreal);
addParameter(p, 'rmax_m',            37500, @isreal); % <- default for NE, gulf coast used 75000
addParameter(p, 'zstep_m',           100,   @isreal);
addParameter(p, 'zmax_m',            3000,  @isreal);
addParameter(p, 'dz_max',            35);
addParameter(p, 'trim_amt',          0.0);
addParameter(p, 'rmse_thresh',       inf,   @isreal);
addParameter(p, 'ep_gamma',          0.1,   @isreal);
addParameter(p, 'az_res',            0.5,   @isreal);
addParameter(p, 'range_res',         250,   @isreal);
addParameter(p, 'nwp_model',         NARR());
addParameter(p, 'gauthreaux_thresh', 5,     @isreal);
addParameter(p, 'seg_scale',         DEFAULT_SEG_SCALE);
addParameter(p, 'seg_rmax',          150000 * DEFAULT_SEG_SCALE);
addParameter(p, 'seg_gpu_device',    []); % options = {1, []}
addParameter(p, 'seg_img_size',      ceil(500 * DEFAULT_SEG_SCALE));
addParameter(p, 'seg_rain_value',    []); % options = {-inf, nan, []}
addParameter(p, 'dz_trim',           0.0,   @isreal);
parse(p, radar_path, station, varargin{:});
params = p.Results;

%%% BUILD MASKS FROM SEGMENTER %%%
if params.seg_net_path
    try
        seg_net = load_segment_net(params.seg_net_path, params.seg_gpu_device);
        % get the segmented img (in cartesian coords)
        [SEG_MASK_RAW, SEG_X, SEG_Y] = segment_scan(radar_aligned, ...
                                                    seg_net, ...
                                                    params.seg_rmax, ...
                                                    params.seg_gpu_device, ...
                                                    params.seg_img_size);
                                                      
        % now interpolate to a full mask of size sz (in radial coords)
        % first, get cartesian X and Y of each pixel in final mask
        [MASK_X, MASK_Y] = pol2cart(AZ, RANGE, HEIGHT);
        
        % build an interpolant for SEG_MASK_RAW
        seg_interpolant = griddedInterpolant({SEG_X, fliplr(SEG_Y)}, flipud(SEG_MASK_RAW), 'nearest');
        
        SEG_MASK = seg_interpolant(MASK_X, MASK_Y);
        
        % convert SEG_MASK to a binary mask with true == rain
        % this is throwing out the segmenting of background pixels that the
        % segmenter does, but the background will already be masked by
        % other masks
        SEG_MASK = (SEG_MASK == SEG_RAIN_LABEL);
    catch err
        fprintf('Error loading scan segmenter %s.', wind_file);
        fprintf('Exception report:\n%s', getReport(err));
        
        SEG_MASK = false(sz);
    end
else
    SEG_MASK = false(sz);
end
