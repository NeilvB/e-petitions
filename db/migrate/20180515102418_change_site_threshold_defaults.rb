class ChangeSiteThresholdDefaults < ActiveRecord::Migration
  def up
    change_column_default(
      :sites,
      :threshold_for_response,
      1000,
    )

    change_column_default(
      :sites,
      :threshold_for_debate,
      5000
    )
  end

  def down
    change_column_default(
      :sites,
      :threshold_for_response,
      10000
    )

    change_column_default(
      :sites,
      :threshold_for_debate,
      5000
    )
  end
end
