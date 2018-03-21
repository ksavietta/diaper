class AdjustmentsController < ApplicationController
  before_action :set_adjustment, only: %i[show]

  # GET /adjustments
  # GET /adjustments.json
  def index
    @selected_location = filter_params[:at_location]
    @adjustments = current_organization.adjustments.filter(filter_params)

    @storage_locations = Adjustment.storage_locations_adjusted_for(current_organization).uniq
  end

  # GET /adjustments/1
  # GET /adjustments/1.json
  def show
    # Stuff!
  end

  # GET /adjustments/new
  def new
    @adjustment = current_organization.adjustments.new
    @adjustment.line_items.build
    @storage_locations = current_organization.storage_locations
    @items = current_organization.items.alphabetized
  end

  # POST /adjustments
  def create
    @adjustment = current_organization.adjustments.new(adjustment_params)
    @storage_locations = current_organization.storage_locations
    @items = current_organization.items.alphabetized

    if @adjustment.valid?
      @adjustment.storage_location.adjust!(@adjustment)

      if @adjustment.save
        redirect_to adjustment_path(@adjustment), notice: "Adjustment was successfully created."
      else
        # FIXME: don't use html_Safe
        flash[:error] = safe_join(@adjustment.errors
                                           .collect do |model, message|
                                             ["#{model}: " + message, content_tag(:br)]
                                           end.flatten)
        render :new
      end

    else
      flash[:error] = safe_join(@adjustment.errors
                                           .collect do |model, message|
                                             ["#{model}: " + message, content_tag(:br)]
                                           end.flatten)
      render :new
    end
  rescue Errors::InsufficientAllotment => ex
    flash[:error] = ex.message
    render :new
  end

  private

  def set_adjustment
    @adjustment = current_organization.adjustments.find(params[:id])
  end

  def adjustment_params
    params.require(:adjustment).permit(:organization_id, :storage_location_id, :comment,
                                       line_items_attributes: %I[item_id quantity _destroy])
  end

  def filter_params
    return {} unless params.key?(:filters)
    params.require(:filters).slice(:at_location)
  end
end