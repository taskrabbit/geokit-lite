class GeokitLite
  VERSION = '0.0.1'

  PI_DIV_RAD = 0.0174
  KMS_PER_MILE = 1.609
  NMS_PER_MILE = 0.868976242
  EARTH_RADIUS_IN_MILES = 3963.19
  EARTH_RADIUS_IN_KMS = EARTH_RADIUS_IN_MILES * KMS_PER_MILE
  EARTH_RADIUS_IN_NMS = EARTH_RADIUS_IN_MILES * NMS_PER_MILE
  MILES_PER_LATITUDE_DEGREE = 69.1
  KMS_PER_LATITUDE_DEGREE = MILES_PER_LATITUDE_DEGREE * KMS_PER_MILE
  NMS_PER_LATITUDE_DEGREE = MILES_PER_LATITUDE_DEGREE * NMS_PER_MILE
  LATITUDE_DEGREES = EARTH_RADIUS_IN_MILES / MILES_PER_LATITUDE_DEGREE

  DEFAULT_OPTIONS = {
    :units => :miles,
    :formula => :flat,
    :lat_column_name => 'lat',
    :lng_column_name => 'lng'
  }

  class << self

    # Returns the distance between two points.  The from and to parameters are
    # required to have lat and lng attributes.  Valid options are:
    # :units - valid values are :miles, :kms, :nms (Geokit::default_units is the default)
    # :formula - valid values are :flat or :sphere (Geokit::default_formula is the default)
    def distance_between(from, to, opts = {})
      opts.reverse_merge!(DEFAULT_OPTIONS)

      return 0.0 if from == to # fixes a "zero-distance" bug
      units = opts[:units]
      formula = opts[:formula]
      case formula
      when :sphere
        begin
          units_sphere_multiplier(units) *
              Math.acos( Math.sin(deg2rad(from.first)) * Math.sin(deg2rad(to.first)) +
              Math.cos(deg2rad(from.first)) * Math.cos(deg2rad(to.first)) *
              Math.cos(deg2rad(to.last) - deg2rad(from.last)))
        rescue Errno::EDOM
          0.0
        end
      when :flat
        Math.sqrt((units_per_latitude_degree(units)*(from.first-to.first))**2 +
            (units_per_longitude_degree(from.first, units)*(from.last-to.last))**2)
      end
    end


    # Returns the distance calculation to be used as a display column or a condition.  This
    # is provide for anyone wanting access to the raw SQL.
    def distance_sql(lat, lng, opts = {})
      opts.reverse_merge!(DEFAULT_OPTIONS)

      opts[:qualified_lat_column_name] = [opts[:table_name], opts[:lat_column_name]].compact.join('.')
      opts[:qualified_lng_column_name] = [opts[:table_name], opts[:lng_column_name]].compact.join('.')

      case opts[:formula]
      when :sphere
        sql = sphere_distance_sql(lat, lng, opts)
      when :flat
        sql = flat_distance_sql(lat, lng, opts)
      end
      sql
    end


    protected

    def sphere_distance_sql(lat, lng, opts)
      lat = deg2rad(lat)
      lng = deg2rad(lng)
      multiplier = units_sphere_multiplier(opts[:units])

      %|
      (ACOS(least(1,COS(#{lat})*COS(#{lng})*COS(RADIANS(#{opts[:qualified_lat_column_name]}))*COS(RADIANS(#{opts[:qualified_lng_column_name]}))+
      COS(#{lat})*SIN(#{lng})*COS(RADIANS(#{opts[:qualified_lat_column_name]}))*SIN(RADIANS(#{opts[:qualified_lng_column_name]}))+
      SIN(#{lat})*SIN(RADIANS(#{opts[:qualified_lat_column_name]}))))*#{multiplier})
      |
    end

    def flat_distance_sql(lat, lng, opts)
      lat_degree_units = units_per_latitude_degree(opts[:units])
      lng_degree_units = units_per_longitude_degree(lat, opts[:units])

      %|
      SQRT(POW(#{lat_degree_units}*(#{lat}-#{opts[:qualified_lat_column_name]}),2)+
      POW(#{lng_degree_units}*(#{lng}-#{opts[:qualified_lng_column_name]}),2))
      |
    end

    def deg2rad(degrees)
      degrees.to_f / 180.0 * Math::PI
    end

    def rad2deg(rad)
      rad.to_f * 180.0 / Math::PI
    end


    # Returns the multiplier used to obtain the correct distance units.
    def units_sphere_multiplier(units)
      case units
        when :kms; EARTH_RADIUS_IN_KMS
        when :nms; EARTH_RADIUS_IN_NMS
        else EARTH_RADIUS_IN_MILES
      end
    end

    # Returns the number of units per latitude degree.
    def units_per_latitude_degree(units)
      case units
        when :kms; KMS_PER_LATITUDE_DEGREE
        when :nms; NMS_PER_LATITUDE_DEGREE
        else MILES_PER_LATITUDE_DEGREE
      end
    end

    # Returns the number units per longitude degree.
    def units_per_longitude_degree(lat, units)
      miles_per_longitude_degree = (LATITUDE_DEGREES * Math.cos(lat * PI_DIV_RAD)).abs
      case units
        when :kms; miles_per_longitude_degree * KMS_PER_MILE
        when :nms; miles_per_longitude_degree * NMS_PER_MILE
        else miles_per_longitude_degree
      end
    end
  end
end
