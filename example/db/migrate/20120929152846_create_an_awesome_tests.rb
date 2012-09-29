class CreateAnAwesomeTests < ActiveRecord::Migration
  def change
    create_table :an_awesome_tests do |t|
      t.string :title
      t.text :description

      t.timestamps
    end
  end
end
